package com.example.snehsaathi.core

import android.content.Context
import android.media.MediaRecorder
import android.media.ToneGenerator
import android.media.AudioManager
import android.os.Build
import android.util.Log
import com.example.snehsaathi.BuildConfig
import kotlinx.coroutines.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.MultipartBody
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.asRequestBody
import org.json.JSONObject
import java.io.File
import java.util.concurrent.TimeUnit

class VoiceInputHelper(
    private val context: Context,
    private val languageCode: String = "hi-IN",
    private val onResult: (String) -> Unit,
    private val onListeningStart: () -> Unit,
    private val onListeningStop: () -> Unit,
    private val onRmsLevel: ((Float) -> Unit)? = null // 🔊 KEEP SAFE, AVOID RECURSION
) {
    private var mediaRecorder: MediaRecorder? = null
    private var audioFile: File? = null
    private var isRecording = false
    private val scope = CoroutineScope(Dispatchers.IO)
    private var silenceJob: Job? = null
    private val client = OkHttpClient.Builder().readTimeout(30, TimeUnit.SECONDS).build()
    private val toneGenerator = ToneGenerator(AudioManager.STREAM_NOTIFICATION, 100)

    fun startListening() {
        if (isRecording) return
        Log.d("VOICE_DEBUG", "startListening called")

        // Play start tone
        toneGenerator.startTone(ToneGenerator.TONE_PROP_BEEP)

        audioFile = File(context.cacheDir, "audio_record.m4a")
        
        mediaRecorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            MediaRecorder(context)
        } else {
            @Suppress("DEPRECATION")
            MediaRecorder()
        }.apply {
            setAudioSource(MediaRecorder.AudioSource.MIC)
            setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
            setOutputFile(audioFile!!.absolutePath)
            
            try {
                prepare()
                start()
                isRecording = true
                onListeningStart()
                startSilenceDetection()
            } catch (e: Exception) {
                Log.e("VOICE_DEBUG", "MediaRecorder prepare() failed", e)
            }
        }
    }

    private fun startSilenceDetection() {
        silenceJob?.cancel()
        silenceJob = scope.launch {
            var silenceDuration = 0L
            val checkInterval = 200L
            val threshold = 1500 // Adjust based on testing

            while (isRecording) {
                delay(checkInterval)
                // Check isRecording again in case stopListening was called from elsewhere
                if (!isRecording) break
                val amplitude = mediaRecorder?.maxAmplitude ?: 0
                if (amplitude < threshold) {
                    silenceDuration += checkInterval
                } else {
                    silenceDuration = 0
                }

                if (silenceDuration > 4000) { // 4.0 seconds of silence
                    Log.d("VOICE_DEBUG", "Silence detected, stopping...")
                    withContext(Dispatchers.Main) {
                        stopListening()
                    }
                    break
                }
            }
        }
    }

    fun stopListening() {
        if (!isRecording) return
        Log.d("VOICE_DEBUG", "stopListening called")
        isRecording = false
        silenceJob?.cancel()
        onListeningStop()

        // Play stop tone
        toneGenerator.startTone(ToneGenerator.TONE_PROP_BEEP2)
        
        // Stop & release MediaRecorder
        try {
            mediaRecorder?.apply {
                // Only stop if the recorder was started (prepare was called)
                try {
                    stop()
                } catch (e: Exception) {
                    Log.e("VOICE_DEBUG", "MediaRecorder stop() failed (expected if prepare failed)", e)
                }
                release()
            }
        } catch (e: Exception) {
            Log.e("VOICE_DEBUG", "MediaRecorder release() failed", e)
        } finally {
            mediaRecorder = null
        }
        
        // Transcribe audio
        audioFile?.let { file ->
            scope.launch {
                try {
                    val text = transcribeAudio(file)
                    if (text.isNotBlank() && text.trim().lowercase() != "null") {
                        onResult(text)
                    }
                } catch (e: Exception) {
                    Log.e("VOICE_DEBUG", "Transcription failed", e)
                    val errorMessage = if (languageCode == "en-IN") "There is a slight issue. Could you please speak again?" else "Abhi thoda issue hai. Kya aap dobara bol sakte hain?"
                    onResult(errorMessage)
                }
            }
        }
    }

    private fun transcribeAudio(file: File): String {
        Log.d("VOICE_DEBUG", "Transcribing audio with Sarvam...")
        val body = MultipartBody.Builder()
            .setType(MultipartBody.FORM)
            .addFormDataPart("file", file.name,
                file.asRequestBody("audio/mp4".toMediaType()))
            .addFormDataPart("model", "saaras:v3")
            .addFormDataPart("language_code", languageCode)
            .addFormDataPart("mode", "codemix")
            .build()

        val request = Request.Builder()
            .url("https://api.sarvam.ai/speech-to-text")
            .addHeader("api-subscription-key", BuildConfig.SARVAM_API_KEY)
            .post(body)
            .build()

        val response = client.newCall(request).execute()
        val responseStr = response.body?.string() ?: ""
        if (!response.isSuccessful) {
            throw Exception("Sarvam STT Error: $responseStr")
        }
        return JSONObject(responseStr).getString("transcript")
    }

    fun destroy() {
        if (isRecording) {
            stopListening()
        }
        scope.cancel()
    }
}
