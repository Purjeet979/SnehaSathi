package com.example.snehsaathi.core

interface AIService {
    suspend fun reply(userText: String, emotion: Emotion = Emotion.NEUTRAL): String
}
