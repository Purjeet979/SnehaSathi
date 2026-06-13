package com.example.snehsaathi.data.repository

import android.content.Context
import dagger.hilt.android.qualifiers.ApplicationContext
import java.nio.MappedByteBuffer
import java.nio.channels.FileChannel
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.math.sqrt

@Singleton
class LocalEmbeddingEngine @Inject constructor(
    @ApplicationContext private val context: Context
) {
    // Note: The model file "embedding_model.tflite" must be added to app/src/main/assets/
    private val interpreter: Any? by lazy {
        try {
            val model = loadModelFile(context)
            // LiteRT Interpreter would be used here once model is available
            // com.google.ai.edge.litert.LiteRtInterpreter.create(model)
            @Suppress("UNUSED_VARIABLE")
            val placeholder = model
            null // placeholder until LiteRT interpreter wrapper is added at runtime
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    private fun loadModelFile(context: Context): MappedByteBuffer {
        val assetFileDescriptor = context.assets.openFd("embedding_model.tflite")
        return assetFileDescriptor.createInputStream().use { inputStream ->
            val fileChannel = inputStream.channel
            val startOffset = assetFileDescriptor.startOffset
            val declaredLength = assetFileDescriptor.declaredLength
            fileChannel.map(FileChannel.MapMode.READ_ONLY, startOffset, declaredLength)
        }
    }

    fun embed(text: String): FloatArray {
        // Tokenize -> run inference -> return 384-dim vector
        // LiteRT inference disabled until model file & LiteRT interpreter are available
        // val tokens = tokenize(text)
        // val output = Array(1) { FloatArray(384) }
        // interpreter?.run(tokens, output)
        // return output[0]
        @Suppress("DEPRECATION")
        return FloatArray(384) { 0f }
    }

    fun cosineSimilarity(a: FloatArray, b: FloatArray): Float {
        val dot = a.zip(b).sumOf { (x, y) -> (x * y).toDouble() }.toFloat()
        val normA = sqrt(a.sumOf { (it * it).toDouble() }.toFloat())
        val normB = sqrt(b.sumOf { (it * it).toDouble() }.toFloat())
        return dot / (normA * normB + 1e-8f)
    }

    private fun tokenize(text: String): Array<IntArray> {
        // Placeholder for a real BPE tokenizer implementation
        // For now, it returns a zeroed array that won't crash the interpreter
        return arrayOf(IntArray(128) { 0 })
    }
}
