package com.example.snehsaathi.core

enum class Emotion { SAD, ANXIOUS, NOSTALGIC, HAPPY, NEUTRAL }

object EmotionalEngine {
    suspend fun detectEmotion(transcript: String): Emotion {
        val prompt = """
            Is sentence mein kya emotion hai? Sirf ek word return karo:
            SAD, HAPPY, ANXIOUS, NEUTRAL, NOSTALGIC
            Sentence: "$transcript"
        """.trimIndent()
        
        return try {
            val result = SarvamClient.chat(listOf(mapOf("role" to "user", "content" to prompt)))
            when {
                result.contains("SAD", ignoreCase = true) -> Emotion.SAD
                result.contains("ANXIOUS", ignoreCase = true) -> Emotion.ANXIOUS
                result.contains("NOSTALGIC", ignoreCase = true) -> Emotion.NOSTALGIC
                result.contains("HAPPY", ignoreCase = true) -> Emotion.HAPPY
                else -> Emotion.NEUTRAL
            }
        } catch (e: Exception) {
            Emotion.NEUTRAL
        }
    }
}
