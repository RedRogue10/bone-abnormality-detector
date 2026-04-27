package com.example.bone_abnormality_detector

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.util.Log
import androidx.exifinterface.media.ExifInterface
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.tensorflow.lite.Interpreter
import java.io.ByteArrayOutputStream
import java.io.FileInputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.channels.FileChannel
import kotlin.math.sqrt

class CamPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    companion object {
        private const val TAG = "CamPlugin"
        private const val CHANNEL = "bone_cam_processor"
        private val CAM_MODELS = mapOf(
            "elbow"    to "flutter_assets/assets/models/cam_elbow.tflite",
            "finger"   to "flutter_assets/assets/models/cam_finger.tflite",
            "forearm"  to "flutter_assets/assets/models/cam_forearm.tflite",
            "hand"     to "flutter_assets/assets/models/cam_hand.tflite",
            "humerus"  to "flutter_assets/assets/models/cam_humerus.tflite",
            "shoulder" to "flutter_assets/assets/models/cam_shoulder.tflite",
            "wrist"    to "flutter_assets/assets/models/cam_wrist.tflite",
        )
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "generateCAM") { result.notImplemented(); return }
        val imagePath = call.argument<String>("imagePath") ?: run { result.success(null); return }
        val bonePart  = call.argument<String>("bonePart")  ?: run { result.success(null); return }
        try {
            val bytes = generateCAM(imagePath, bonePart)
            result.success(bytes)
        } catch (e: Exception) {
            Log.e(TAG, "generateCAM failed for $bonePart: ${e.message}", e)
            result.error("CAM_ERROR", e.message, e.stackTraceToString())
        }
    }

    private fun generateCAM(imagePath: String, bonePart: String): ByteArray? {
        val modelAsset = CAM_MODELS[bonePart] ?: return null
        Log.d(TAG, "Loading model: $modelAsset")

        val fd = context.assets.openFd(modelAsset)
        val modelBuffer = FileInputStream(fd.fileDescriptor).channel.map(
            FileChannel.MapMode.READ_ONLY, fd.startOffset, fd.declaredLength
        )
        val interpreter = Interpreter(modelBuffer)

        // Input shape: [1, H, W, 3]
        val inputShape = interpreter.getInputTensor(0).shape()
        val inputH = inputShape[1]
        val inputW = inputShape[2]
        Log.d(TAG, "Input shape: ${inputShape.toList()}")

        val originalBitmap = BitmapFactory.decodeFile(imagePath)
            ?.let { applyExifRotation(imagePath, it) }
            ?: throw IllegalStateException("Cannot decode image at $imagePath")
        val resized = Bitmap.createScaledBitmap(originalBitmap, inputW, inputH, true)

        val inputBuf = ByteBuffer.allocateDirect(inputH * inputW * 3 * 4)
            .order(ByteOrder.nativeOrder())
        for (y in 0 until inputH) {
            for (x in 0 until inputW) {
                val px = resized.getPixel(x, y)
                inputBuf.putFloat(((px shr 16) and 0xFF) / 255f)
                inputBuf.putFloat(((px shr  8) and 0xFF) / 255f)
                inputBuf.putFloat(( px          and 0xFF) / 255f)
            }
        }

        // Auto-detect rank-2 (predictions) and rank-4 (feature map) outputs
        val numOutputs = interpreter.outputTensorCount
        Log.d(TAG, "Model has $numOutputs output(s)")
        var predIdx = -1
        var featIdx = -1
        for (i in 0 until numOutputs) {
            val shape = interpreter.getOutputTensor(i).shape()
            Log.d(TAG, "  Output $i shape: ${shape.toList()}")
            when (shape.size) {
                2 -> predIdx = i
                4 -> featIdx = i
            }
        }
        if (predIdx < 0 || featIdx < 0) {
            throw IllegalStateException(
                "Unexpected outputs: need rank-2 (predictions) and rank-4 (feature map), " +
                "found $numOutputs output(s)"
            )
        }

        // onnx2tf always outputs NHWC, so feature map is [1, H, W, C]
        val featShape = interpreter.getOutputTensor(featIdx).shape()
        val featH = featShape[1]
        val featW = featShape[2]
        val featC = featShape[3]
        Log.d(TAG, "Feature map: [1, $featH, $featW, $featC]")

        val predShape = interpreter.getOutputTensor(predIdx).shape()
        val outPred: Array<FloatArray> = Array(predShape[0]) { FloatArray(predShape[1]) }
        val outFeat: Array<Array<Array<FloatArray>>> =
            Array(1) { Array(featH) { Array(featW) { FloatArray(featC) } } }

        val outputs = HashMap<Int, Any>()
        outputs[predIdx] = outPred
        outputs[featIdx] = outFeat
        interpreter.runForMultipleInputsOutputs(arrayOf<Any>(inputBuf), outputs)
        interpreter.close()

        val probs = outPred[0]
        Log.d(TAG, "Probs: ${probs.toList()}")

        // Eigen-CAM: power iteration to find dominant activation direction,
        // then project the feature map onto it for the spatial heatmap.
        val rows = featH * featW
        var v = FloatArray(featC) { 1f / sqrt(featC.toFloat()) }
        repeat(10) {
            // mv = M @ v  [rows]
            val mv = FloatArray(rows) { r ->
                val y = r / featW; val x = r % featW
                var s = 0f
                for (c in 0 until featC) s += outFeat[0][y][x][c] * v[c]
                s
            }
            // v_new = M^T @ mv  [featC]
            val vNew = FloatArray(featC) { c ->
                var s = 0f
                for (r in 0 until rows) {
                    val y = r / featW; val x = r % featW
                    s += outFeat[0][y][x][c] * mv[r]
                }
                s
            }
            val norm = sqrt(vNew.fold(0f) { acc, f -> acc + f * f })
            v = if (norm < 1e-8f) vNew else FloatArray(featC) { vNew[it] / norm }
        }

        // Project each spatial position onto the dominant direction
        val camGrid = Array(featH) { y ->
            FloatArray(featW) { x ->
                var s = 0f
                for (c in 0 until featC) s += outFeat[0][y][x][c] * v[c]
                s
            }
        }

        // Clamp negatives and normalise to [0, 1]
        for (row in camGrid) for (i in row.indices) if (row[i] < 0f) row[i] = 0f
        var maxV = -Float.MAX_VALUE
        for (row in camGrid) for (v2 in row) if (v2 > maxV) maxV = v2
        val range = if (maxV < 1e-8f) 1f else maxV

        // 1. Render jet colours at CAM resolution
        val camBitmap = Bitmap.createBitmap(featW, featH, Bitmap.Config.ARGB_8888)
        for (y in 0 until featH) {
            for (x in 0 until featW) {
                val norm = (camGrid[y][x] / range).coerceIn(0f, 1f)
                val (hr, hg, hb) = jetColor(norm)
                camBitmap.setPixel(x, y, (0xFF shl 24) or (hr shl 16) or (hg shl 8) or hb)
            }
        }

        // 2. Bilinear-upscale to original image size
        val outW = originalBitmap.width
        val outH = originalBitmap.height
        val scaledCam = Bitmap.createScaledBitmap(camBitmap, outW, outH, true)

        // 3. 50/50 blend with the original
        val blended = Bitmap.createBitmap(outW, outH, Bitmap.Config.ARGB_8888)
        for (y in 0 until outH) {
            for (x in 0 until outW) {
                val op = originalBitmap.getPixel(x, y)
                val hp = scaledCam.getPixel(x, y)
                val r = (((op shr 16) and 0xFF) * 0.5f + ((hp shr 16) and 0xFF) * 0.5f).toInt()
                val g = (((op shr  8) and 0xFF) * 0.5f + ((hp shr  8) and 0xFF) * 0.5f).toInt()
                val b = (( op         and 0xFF) * 0.5f + ( hp         and 0xFF) * 0.5f).toInt()
                blended.setPixel(x, y, (0xFF shl 24) or (r shl 16) or (g shl 8) or b)
            }
        }

        val baos = ByteArrayOutputStream()
        blended.compress(Bitmap.CompressFormat.PNG, 100, baos)
        Log.d(TAG, "Eigen-CAM overlay generated: ${baos.size()} bytes")
        return baos.toByteArray()
    }

    private fun applyExifRotation(imagePath: String, bitmap: Bitmap): Bitmap {
        val orientation = try {
            ExifInterface(imagePath).getAttributeInt(
                ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL
            )
        } catch (_: Exception) { ExifInterface.ORIENTATION_NORMAL }

        val degrees = when (orientation) {
            ExifInterface.ORIENTATION_ROTATE_90  -> 90f
            ExifInterface.ORIENTATION_ROTATE_180 -> 180f
            ExifInterface.ORIENTATION_ROTATE_270 -> 270f
            else -> return bitmap
        }
        val matrix = Matrix().apply { postRotate(degrees) }
        return Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
    }

    // Piecewise-linear jet colormap: t=0 → dark blue, t=0.5 → cyan/green, t=1 → dark red.
    private fun jetColor(t: Float): Triple<Int, Int, Int> {
        val r = lerp(t, floatArrayOf(0f, 0.35f, 0.66f, 0.89f, 1f),
                        floatArrayOf(0f, 0f,    1f,    1f,    0.5f))
        val g = lerp(t, floatArrayOf(0f,    0.125f, 0.375f, 0.64f, 0.91f, 1f),
                        floatArrayOf(0f,    0f,     1f,     1f,    0f,    0f))
        val b = lerp(t, floatArrayOf(0f,  0.11f, 0.34f, 0.65f, 1f),
                        floatArrayOf(0.5f, 1f,    1f,    0f,    0f))
        return Triple(
            (r * 255).toInt().coerceIn(0, 255),
            (g * 255).toInt().coerceIn(0, 255),
            (b * 255).toInt().coerceIn(0, 255),
        )
    }

    private fun lerp(t: Float, xs: FloatArray, ys: FloatArray): Float {
        if (t <= xs.first()) return ys.first()
        if (t >= xs.last())  return ys.last()
        val i = xs.indexOfFirst { it > t } - 1
        val frac = (t - xs[i]) / (xs[i + 1] - xs[i])
        return ys[i] + frac * (ys[i + 1] - ys[i])
    }
}
