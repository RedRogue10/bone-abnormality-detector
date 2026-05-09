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

        // Auto-detect predictions (rank 1–2) and feature map (rank 3–4).
        // Uses ByteBuffer outputs to stay shape-agnostic at the Java/Kotlin layer.
        val numOutputs = interpreter.outputTensorCount
        Log.d(TAG, "Model has $numOutputs output(s)")
        var predIdx = -1
        var featIdx = -1
        for (i in 0 until numOutputs) {
            val shape = interpreter.getOutputTensor(i).shape()
            Log.d(TAG, "  Output $i: shape=${shape.toList()}, rank=${shape.size}")
            when (shape.size) {
                1, 2 -> if (predIdx < 0) predIdx = i
                3, 4 -> if (featIdx < 0) featIdx = i
            }
        }
        if (predIdx < 0 || featIdx < 0) {
            val shapes = (0 until numOutputs).map { interpreter.getOutputTensor(it).shape().toList() }
            throw IllegalStateException(
                "Cannot find required outputs (predictions rank≤2 + feature map rank≥3). " +
                "Model has $numOutputs output(s) with shapes: $shapes"
            )
        }

        val featShape = interpreter.getOutputTensor(featIdx).shape()
        val predShape = interpreter.getOutputTensor(predIdx).shape()

        // Strip optional batch dimension: [1,H,W,C] → (H,W,C) or [H,W,C] → (H,W,C)
        val (featH, featW, featC) = when (featShape.size) {
            4 -> Triple(featShape[1], featShape[2], featShape[3])
            3 -> Triple(featShape[0], featShape[1], featShape[2])
            else -> throw IllegalStateException("Unexpected feature map rank: ${featShape.size}")
        }
        Log.d(TAG, "Feature map: [${featH}×${featW}×${featC}]")

        // Allocate typed-array outputs — TFLite on Android requires typed arrays for outputs
        val predArr: Any = if (predShape.size == 1)
            FloatArray(predShape[0])
        else
            Array(predShape[0]) { FloatArray(predShape[1]) }

        val featArr: Any = if (featShape.size == 3)
            Array(featH) { Array(featW) { FloatArray(featC) } }
        else
            Array(1) { Array(featH) { Array(featW) { FloatArray(featC) } } }

        val outputs = HashMap<Int, Any>()
        outputs[predIdx] = predArr
        outputs[featIdx] = featArr
        interpreter.runForMultipleInputsOutputs(arrayOf<Any>(inputBuf), outputs)
        interpreter.close()

        // Extract predictions — unwrap batch dim if rank 2
        val probs: FloatArray = if (predShape.size == 1)
            predArr as FloatArray
        else
            (predArr as Array<FloatArray>)[0]
        Log.d(TAG, "Probs: ${probs.toList()}")

        // Build accessor for feature map — handles rank 3 [H,W,C] and rank 4 [1,H,W,C]
        val feat: (Int, Int, Int) -> Float = if (featShape.size == 3) {
            val f = featArr as Array<Array<FloatArray>>
            { y, x, c -> f[y][x][c] }
        } else {
            val f = (featArr as Array<Array<Array<FloatArray>>>)[0]
            { y, x, c -> f[y][x][c] }
        }

        // Standard CAM: the model already baked in fc_weights × feature_map,
        // producing cam_all [1, H, W, K]. Extract class 1 (abnormal) directly.
        val abnormalIdx = if (featC > 1) 1 else 0
        Log.d(TAG, "Extracting standard CAM for class index $abnormalIdx (abnormal) from cam_all [H=$featH W=$featW K=$featC]")
        val camGrid = Array(featH) { y ->
            FloatArray(featW) { x -> feat(y, x, abnormalIdx) }
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

        // 3. Activation-proportional alpha blend.
        //    Alpha = bilinear-upsampled CAM value × maxAlpha, so low-activation
        //    pixels stay transparent (no blue tint) and high-activation pixels
        //    receive up to 75 % heatmap colour on top of the original.
        val maxAlpha = 0.75f
        val blended = Bitmap.createBitmap(outW, outH, Bitmap.Config.ARGB_8888)
        for (y in 0 until outH) {
            for (x in 0 until outW) {
                // Bilinear-interpolate the raw CAM activation at this pixel.
                val fx = x.toFloat() / outW * featW
                val fy = y.toFloat() / outH * featH
                val x0 = fx.toInt().coerceIn(0, featW - 1)
                val y0 = fy.toInt().coerceIn(0, featH - 1)
                val x1 = (x0 + 1).coerceIn(0, featW - 1)
                val y1 = (y0 + 1).coerceIn(0, featH - 1)
                val dx = fx - x0; val dy = fy - y0
                val camRaw = camGrid[y0][x0] * (1 - dx) * (1 - dy) +
                             camGrid[y0][x1] * dx        * (1 - dy) +
                             camGrid[y1][x0] * (1 - dx) * dy        +
                             camGrid[y1][x1] * dx        * dy
                val alpha = (camRaw / range).coerceIn(0f, 1f) * maxAlpha

                val op = originalBitmap.getPixel(x, y)
                val hp = scaledCam.getPixel(x, y)
                val or2 = (op shr 16) and 0xFF
                val og  = (op shr  8) and 0xFF
                val ob  =  op         and 0xFF
                val hr  = (hp shr 16) and 0xFF
                val hg  = (hp shr  8) and 0xFF
                val hb  =  hp         and 0xFF
                val r = (or2 * (1f - alpha) + hr * alpha).toInt().coerceIn(0, 255)
                val g = (og  * (1f - alpha) + hg * alpha).toInt().coerceIn(0, 255)
                val b = (ob  * (1f - alpha) + hb * alpha).toInt().coerceIn(0, 255)
                blended.setPixel(x, y, (0xFF shl 24) or (r shl 16) or (g shl 8) or b)
            }
        }

        val baos = ByteArrayOutputStream()
        blended.compress(Bitmap.CompressFormat.PNG, 100, baos)
        Log.d(TAG, "Standard CAM overlay generated: ${baos.size()} bytes")
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
