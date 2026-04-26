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
import kotlin.math.abs

class CamPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    companion object {
        private const val TAG = "CamPlugin"
        private const val CHANNEL = "bone_cam_processor"
        private val CAM_MODELS = mapOf(
            "elbow"   to "flutter_assets/assets/models/elbow_cam.tflite",
            "finger"  to "flutter_assets/assets/models/finger_cam.tflite",
            "forearm" to "flutter_assets/assets/models/forearm_cam.tflite",
            "wrist"   to "flutter_assets/assets/models/wrist_cam.tflite",
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

        // Auto-detect which output is predictions [1,2] vs cam_all [1,2,H,W]
        val numOutputs = interpreter.outputTensorCount
        Log.d(TAG, "Model has $numOutputs output(s)")
        var predIdx = -1
        var camIdx  = -1
        for (i in 0 until numOutputs) {
            val shape = interpreter.getOutputTensor(i).shape()
            Log.d(TAG, "  Output $i shape: ${shape.toList()}")
            when (shape.size) {
                2    -> predIdx = i   // [1, numClasses]
                4    -> camIdx  = i   // [1, C, H, W] or [1, H, W, C]
            }
        }
        if (predIdx < 0 || camIdx < 0) {
            throw IllegalStateException(
                "Unexpected output tensors: found $numOutputs output(s), " +
                "need one rank-2 (predictions) and one rank-4 (CAM)"
            )
        }

        val camShape = interpreter.getOutputTensor(camIdx).shape()
        // Support both NCHW [1, C, H, W] and NHWC [1, H, W, C]
        val numClasses: Int
        val camH: Int
        val camW: Int
        if (camShape[1] < camShape[2] && camShape[1] < camShape[3]) {
            // NCHW: classes is the small dim at index 1
            numClasses = camShape[1]; camH = camShape[2]; camW = camShape[3]
        } else {
            // NHWC: classes is the small dim at index 3
            numClasses = camShape[3]; camH = camShape[1]; camW = camShape[2]
        }
        val isNCHW = camShape[1] == numClasses
        Log.d(TAG, "CAM idx=$camIdx shape=${camShape.toList()} isNCHW=$isNCHW camH=$camH camW=$camW")

        val predShape = interpreter.getOutputTensor(predIdx).shape()
        val out0: Array<FloatArray> = Array(predShape[0]) { FloatArray(predShape[1]) }
        // Allocate CAM always as [1, numClasses, camH, camW] in NCHW layout
        val out1Nchw: Array<Array<Array<FloatArray>>> =
            Array(1) { Array(numClasses) { Array(camH) { FloatArray(camW) } } }
        val out1Nhwc: Array<Array<Array<FloatArray>>> =
            Array(1) { Array(camH) { Array(camW) { FloatArray(numClasses) } } }

        val outputs = HashMap<Int, Any>()
        outputs[predIdx] = out0
        outputs[camIdx]  = if (isNCHW) out1Nchw else out1Nhwc
        interpreter.runForMultipleInputsOutputs(arrayOf<Any>(inputBuf), outputs)
        interpreter.close()

        // Resolve predicted class
        val probs    = out0[0]
        val classIdx = probs.indices.maxByOrNull { probs[it] } ?: 0
        Log.d(TAG, "Predicted class=$classIdx probs=${probs.toList()}")

        // Extract 2-D CAM grid [camH][camW]
        val camGrid: Array<FloatArray> = if (isNCHW) {
            out1Nchw[0][classIdx]
        } else {
            Array(camH) { y -> FloatArray(camW) { x -> out1Nhwc[0][y][x][classIdx] } }
        }

        // Normalise
        var minV =  Float.MAX_VALUE
        var maxV = -Float.MAX_VALUE
        for (row in camGrid) for (v in row) { if (v < minV) minV = v; if (v > maxV) maxV = v }
        val range = if (abs(maxV - minV) < 1e-8f) 1f else maxV - minV

        // 1. Render jet colours into a small CAM-resolution bitmap
        val camBitmap = Bitmap.createBitmap(camW, camH, Bitmap.Config.ARGB_8888)
        for (y in 0 until camH) {
            for (x in 0 until camW) {
                val norm = ((camGrid[y][x] - minV) / range).coerceIn(0f, 1f)
                val (hr, hg, hb) = jetColor(norm)
                camBitmap.setPixel(x, y, (0xFF shl 24) or (hr shl 16) or (hg shl 8) or hb)
            }
        }

        // 2. Bilinear-upscale to full image size → smooth radiating gradients
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
        Log.d(TAG, "CAM overlay generated: ${baos.size()} bytes")
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

    // Piecewise-linear jet colormap matching matplotlib's definition.
    // t=0 → dark blue, t=0.5 → yellow-green, t=1 → dark red.
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
