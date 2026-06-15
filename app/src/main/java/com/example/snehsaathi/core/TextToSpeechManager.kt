package com.example.snehsaathi.core

import android.content.Context
import android.media.MediaPlayer
import android.speech.tts.TextToSpeech
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.util.Locale

class TextToSpeechManager(private val context: Context) {
    
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private var currentMediaPlayer: MediaPlayer? = null
    
    private var nativeTts: TextToSpeech? = null
    private var isNativeReady = false

    init {
        nativeTts = TextToSpeech(context) { status ->
            if (status == TextToSpeech.SUCCESS) {
                nativeTts?.language = Locale("hi", "IN")
                nativeTts?.setOnUtteranceProgressListener(object : android.speech.tts.UtteranceProgressListener() {
                    override fun onStart(utteranceId: String?) {}
                    override fun onDone(utteranceId: String?) {
                        val callback = currentOnComplete
                        currentOnComplete = null
                        callback?.invoke()
                    }
                    override fun onError(utteranceId: String?) {
                        val callback = currentOnComplete
                        currentOnComplete = null
                        callback?.invoke()
                    }
                })
                isNativeReady = true
            }
        }
    }

    private var currentOnComplete: (() -> Unit)? = null

    fun speak(text: String, emotion: Emotion = Emotion.NEUTRAL, language: String = "hi", onComplete: (() -> Unit)? = null) {
        // User requested to use native TTS exclusively for all app features to eliminate sound delay
        speakFast(text, language, emotion, onComplete)
    }

    fun speakFast(text: String, language: String = "hi", emotion: Emotion = Emotion.NEUTRAL, onComplete: (() -> Unit)? = null) {
        scope.launch(Dispatchers.Main) {
            currentMediaPlayer?.apply {
                if (isPlaying) stop()
                release()
            }
            currentMediaPlayer = null
            
            if (isNativeReady) {
                currentOnComplete = onComplete
                val params = android.os.Bundle()
                val targetLocale = if (language == "en") Locale.US else Locale("hi", "IN")
                val result = nativeTts?.setLanguage(targetLocale)
                if (result == TextToSpeech.LANG_MISSING_DATA || result == TextToSpeech.LANG_NOT_SUPPORTED) {
                    // Fallback to default if not supported
                    nativeTts?.setLanguage(Locale.getDefault())
                }
                
                val speechRate = when(emotion) {
                    Emotion.SAD -> 0.7f
                    Emotion.ANXIOUS -> 0.85f
                    Emotion.NOSTALGIC -> 0.9f
                    Emotion.HAPPY -> 1.1f
                    else -> 1.0f
                }
                nativeTts?.setSpeechRate(speechRate)
                
                nativeTts?.speak(text, TextToSpeech.QUEUE_FLUSH, params, "sneh_tts_${System.nanoTime()}")
            } else {
                onComplete?.invoke()
            }
        }
    }

    fun stop() {
        currentMediaPlayer?.apply {
            if (isPlaying) stop()
            release()
        }
        currentMediaPlayer = null
        if (isNativeReady) {
            nativeTts?.stop()
        }
    }

    fun destroy() {
        stop()
        nativeTts?.shutdown()
        scope.cancel()
    }
}
