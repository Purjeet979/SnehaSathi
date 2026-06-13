package com.example.snehsaathi.core.tts

import android.content.Context
import android.speech.tts.TextToSpeech
import dagger.hilt.android.qualifiers.ApplicationContext
import java.util.Locale
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class OfflineTtsManager @Inject constructor(
    @ApplicationContext private val context: Context
) : TextToSpeech.OnInitListener {

    private var tts: TextToSpeech? = null
    private var isReady = false

    init {
        tts = TextToSpeech(context, this)
    }

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            tts?.language = Locale("hi", "IN")  // Hindi-IN for Hinglish feel
            tts?.setSpeechRate(1.1f)             // Slightly faster, feels natural
            tts?.setPitch(1.05f)
            isReady = true
        }
    }

    fun speak(text: String, priority: Int = TextToSpeech.QUEUE_FLUSH) {
        if (isReady) {
            tts?.speak(text, priority, null, "sneh_tts_${System.currentTimeMillis()}")
        }
    }

    fun shutdown() = tts?.shutdown()
}
