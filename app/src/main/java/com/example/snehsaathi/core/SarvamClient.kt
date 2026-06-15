package com.example.snehsaathi.core

import com.example.snehsaathi.BuildConfig
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.MediaType.Companion.toMediaType
import org.json.JSONObject
import org.json.JSONArray
import java.util.concurrent.TimeUnit
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

object SarvamClient {

    private const val BASE_URL = "https://api.sarvam.ai"
    private val client = OkHttpClient.Builder()
        .readTimeout(30, TimeUnit.SECONDS)
        .build()

    private val API_KEY = BuildConfig.SARVAM_API_KEY

    suspend fun chat(messages: List<Map<String, String>>): String = withContext(Dispatchers.IO) {
        val messagesArray = JSONArray()
        for (msg in messages) {
            messagesArray.put(JSONObject().put("role", msg["role"]).put("content", msg["content"]))
        }

        val body = JSONObject().apply {
            put("model", "sarvam-30b")
            put("messages", messagesArray)
            put("max_tokens", 300)
        }
        val request = Request.Builder()
            .url("$BASE_URL/v1/chat/completions")
            .addHeader("api-subscription-key", API_KEY)
            .addHeader("Content-Type", "application/json")
            .post(body.toString().toRequestBody("application/json".toMediaType()))
            .build()
        val response = client.newCall(request).execute()
        val responseBody = response.body
        if (responseBody == null) {
            throw Exception("Sarvam API Error: Empty response body")
        }
        val responseStr = responseBody.string()
        if (!response.isSuccessful) {
            throw Exception("Sarvam API Error: $responseStr")
        }
        val json = JSONObject(responseStr)
        val content = json.getJSONArray("choices")
            .getJSONObject(0)
            .getJSONObject("message")
            .optString("content", "")
            
        if (content.isEmpty() || content == "null") {
            throw Exception("Sarvam API returned empty/null content")
        }
        return@withContext content
    }

    suspend fun textToSpeech(text: String, pace: Double = 1.2, languageCode: String = "hi-IN"): ByteArray = withContext(Dispatchers.IO) {
        val body = JSONObject().apply {
            put("inputs", JSONArray().put(text))
            put("target_language_code", languageCode)
            put("speaker", "priya") // Changed to 'priya' for better quality
            put("pace", pace)
            put("model", "bulbul:v3")
        }
        val request = Request.Builder()
            .url("$BASE_URL/text-to-speech")
            .addHeader("api-subscription-key", API_KEY)
            .addHeader("Content-Type", "application/json")
            .post(body.toString().toRequestBody("application/json".toMediaType()))
            .build()
        val response = client.newCall(request).execute()
        val responseBody = response.body
        if (responseBody == null) {
            throw Exception("Sarvam TTS Error: Empty response body")
        }
        val responseStr = responseBody.string()
        if (!response.isSuccessful) {
            throw Exception("Sarvam TTS Error: $responseStr")
        }
        val json = JSONObject(responseStr)
        val base64Audio = json.getJSONArray("audios").getString(0)
        return@withContext android.util.Base64.decode(base64Audio, android.util.Base64.DEFAULT)
    }

    suspend fun translate(text: String, targetLang: String): String = withContext(Dispatchers.IO) {
        val body = JSONObject().apply {
            put("input", text)
            put("source_language_code", "hi-IN")
            put("target_language_code", targetLang)
            put("model", "mayura:v1")
        }
        val request = Request.Builder()
            .url("$BASE_URL/translate")
            .addHeader("api-subscription-key", API_KEY)
            .addHeader("Content-Type", "application/json")
            .post(body.toString().toRequestBody("application/json".toMediaType()))
            .build()
        val response = client.newCall(request).execute()
        val responseBody = response.body
        if (responseBody == null) {
            throw Exception("Sarvam Translate Error: Empty response body")
        }
        val responseStr = responseBody.string()
        if (!response.isSuccessful) {
            throw Exception("Sarvam Translate Error: $responseStr")
        }
        return@withContext JSONObject(responseStr).getString("translated_text")
    }
}
