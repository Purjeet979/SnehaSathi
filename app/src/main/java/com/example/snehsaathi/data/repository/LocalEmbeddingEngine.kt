package com.example.snehsaathi.data.repository

import android.content.Context
import dagger.hilt.android.qualifiers.ApplicationContext
import org.tensorflow.lite.Interpreter
import org.tensorflow.lite.support.common.FileUtil
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.math.sqrt

@Singleton
class LocalEmbeddingEngine @Inject constructor(
    @ApplicationContext private val context: Context
) {
    // Note: The model file "embedding_model.tflite" must be added to app/src/main/assets/
    private val interpreter: Interpreter? by lazy {
        try {
            val model = FileUtil.loadMappedFile(context, "embedding_model.tflite")
            Interpreter(model, Interpreter.Options().apply { numThreads = 2 })
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    fun embed(text: String): FloatArray {
        // Tokenize -> run inference -> return 384-dim vector
        val tokens = tokenize(text)
        val output = Array(1) { FloatArray(384) }
        interpreter?.run(tokens, output)
        return output[0]
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
