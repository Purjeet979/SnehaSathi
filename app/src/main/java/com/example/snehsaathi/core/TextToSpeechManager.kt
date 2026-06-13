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
u
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

    fun speak(text: String, emotion: Emotion = Emotion.NEUTRAL, onComplete: (() -> Unit)? = null) {
        scope.launch {
            try {
                withContext(Dispatchers.Main) {
                    currentMediaPlayer?.apply {
                        if (isPlaying) stop()
                        release()
                    }
                    currentMediaPlayer = null
                }

                val pace = when (emotion) {
                    Emotion.SAD -> 0.7
                    Emotion.ANXIOUS -> 0.75
                    Emotion.HAPPY -> 0.9
                    else -> 1.2
                }
                
                try {
                    val audioBytes = SarvamClient.textToSpeech(text, pace)
                    val tempFile = File(context.cacheDir, "tts_output_${System.nanoTime()}.wav")
                    tempFile.writeBytes(audioBytes)
                    
                    withContext(Dispatchers.Main) {
                        val mediaPlayer = MediaPlayer()
                        mediaPlayer.setDataSource(tempFile.absolutePath)
                        mediaPlayer.prepare()
                        mediaPlayer.start()
                        currentMediaPlayer = mediaPlayer
                        mediaPlayer.setOnCompletionListener {
                            it.release()
                            if (currentMediaPlayer == it) currentMediaPlayer = null
                            tempFile.delete()
                            onComplete?.invoke()
                        }
                    }
                } catch (e: Exception) {
                    // Fallback to Native TTS
                    if (isNativeReady) {
                        currentOnComplete = onComplete
                        withContext(Dispatchers.Main) {
                            val params = android.os.Bundle()
                            nativeTts?.speak(text, TextToSpeech.QUEUE_FLUSH, params, "sneh_tts_${System.nanoTime()}")
                        }
                    } else {
                        withContext(Dispatchers.Main) { onComplete?.invoke() }
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
                withContext(Dispatchers.Main) { onComplete?.invoke() }
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
