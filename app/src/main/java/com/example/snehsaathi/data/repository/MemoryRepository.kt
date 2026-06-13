package com.example.snehsaathi.data.repository

import com.example.snehsaathi.data.local.dao.MemoryDao
import com.example.snehsaathi.data.local.entity.MemoryEntity
import java.nio.ByteBuffer
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class MemoryRepository @Inject constructor(
    private val memoryDao: MemoryDao,
    private val embeddingEngine: LocalEmbeddingEngine
) {
    suspend fun saveMemory(content: String) {
        val embedding = embeddingEngine.embed(content)
        val entity = MemoryEntity(
            content = content,
            embedding = embedding.toByteArray()
        )
        memoryDao.insert(entity)
    }

    suspend fun retrieveRelevantMemories(query: String, topK: Int = 5): List<String> {
        val queryEmbedding = embeddingEngine.embed(query)
        val allMemories = memoryDao.getAll()
        return allMemories
            .map { it to embeddingEngine.cosineSimilarity(queryEmbedding, it.embedding.toFloatArray()) }
            .sortedByDescending { it.second }
            .take(topK)
            .map { it.first.content }
    }

    private fun FloatArray.toByteArray(): ByteArray {
        val buffer = ByteBuffer.allocate(this.size * 4)
        buffer.asFloatBuffer().put(this)
        return buffer.array()
    }

    private fun ByteArray.toFloatArray(): FloatArray {
        val buffer = ByteBuffer.wrap(this)
        val floatBuffer = buffer.asFloatBuffer()
        val floatArray = FloatArray(floatBuffer.capacity())
        floatBuffer.get(floatArray)
        return floatArray
    }
}
