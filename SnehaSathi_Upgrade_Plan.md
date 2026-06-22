# SnehaSathi — Complete Upgrade & Sarvam AI Integration Plan

> **Hackathon Target:** Sarvam Track (USD 500 credits) + Overall Top 10 (USD 200–1000)
> **Project:** SnehaSathi — Voice AI Companion for Elderly Indians
> **GitHub:** https://github.com/Purjeet979/SnehaSathi

---

## Hackathon Impact Score (Before vs After)

| Category | Before | After | What Changes |
|---|---|---|---|
| Concept Strength | 9.2 / 10 | 9.2 / 10 | Already strong, no change needed |
| Voice Quality (STT/TTS) | 5.5 / 10 | 9.0 / 10 | Groq → Sarvam Saaras v3 + Bulbul v3 |
| Indian Language Depth | 6.0 / 10 | 9.5 / 10 | Hinglish codemix support added |
| Track Eligibility | 7.0 / 10 | 9.8 / 10 | Unlocks Sarvam Track prize |

---

## Part 1 — Sarvam AI Integration (Core Change)

### What to Replace and Why

| Current (Groq/Android) | Replace With (Sarvam) | Why It's Better for SnehaSathi |
|---|---|---|
| Android STT `(hi-IN)` | **Saaras v3 — Speech to Text** | Handles Hinglish codemix naturally. No failure when Dadi says "mera BP zyada hai doctor ne bola hai". Supports 8kHz audio. |
| Android TTS `(hi-IN)` | **Bulbul v3 — Text to Speech** | 30+ natural Indian voices. `pace: 0.8` for elderly. Warm Hindi female voice — sounds like a real companion, not a robot. |
| Groq `mixtral-8x7b` LLM | **Sarvam-2B Chat LLM** | Trained on Indian data. Understands cultural context like "Bhai ka shaadi hai" or "Karva Chauth ke liye kya banau". Better Hinglish output. |
| No translation layer | **Mayura — Translation API** | Family portal in English, Dadi speaks Hindi. Ghostwriter letters can be sent in Tamil/Kannada/Bengali to each family member. |

---

### Step-by-Step Code-Level Changes

#### Step 1 — Create SarvamClient.kt

Create a new file `backend/SarvamClient.kt` to replace `GroqClient.kt`.

```kotlin
// backend/SarvamClient.kt

import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.MediaType.Companion.toMediaType
import org.json.JSONObject

object SarvamClient {

    private const val BASE_URL = "https://api.sarvam.ai"
    private val client = OkHttpClient()

    // Get API key from local.properties → BuildConfig
    private val API_KEY = BuildConfig.SARVAM_API_KEY

    // --- Chat LLM (replaces Groq) ---
    fun chat(messages: List<Map<String, String>>): String {
        val body = JSONObject().apply {
            put("model", "sarvam-2b-v0.5")
            put("messages", messages)
            put("max_tokens", 300)
        }
        val request = Request.Builder()
            .url("$BASE_URL/chat/completions")
            .addHeader("api-subscription-key", API_KEY)
            .addHeader("Content-Type", "application/json")
            .post(body.toString().toRequestBody("application/json".toMediaType()))
            .build()
        val response = client.newCall(request).execute()
        val json = JSONObject(response.body!!.string())
        return json.getJSONArray("choices")
                   .getJSONObject(0)
                   .getJSONObject("message")
                   .getString("content")
    }

    // --- Text to Speech (replaces Android TTS) ---
    fun textToSpeech(text: String): ByteArray {
        val body = JSONObject().apply {
            put("inputs", listOf(text))
            put("target_language_code", "hi-IN")
            put("speaker", "meera")   // warm female Hindi voice
            put("pace", 0.8)          // slower for elderly users
            put("model", "bulbul:v3")
        }
        val request = Request.Builder()
            .url("$BASE_URL/text-to-speech")
            .addHeader("api-subscription-key", API_KEY)
            .addHeader("Content-Type", "application/json")
            .post(body.toString().toRequestBody("application/json".toMediaType()))
            .build()
        val response = client.newCall(request).execute()
        val json = JSONObject(response.body!!.string())
        val base64Audio = json.getJSONArray("audios").getString(0)
        return android.util.Base64.decode(base64Audio, android.util.Base64.DEFAULT)
    }

    // --- Translate (for Ghostwriter multilingual letters) ---
    fun translate(text: String, targetLang: String): String {
        val body = JSONObject().apply {
            put("input", text)
            put("source_language_code", "hi-IN")
            put("target_language_code", targetLang)  // e.g. "ta-IN", "kn-IN", "bn-IN"
            put("model", "mayura:v1")
        }
        val request = Request.Builder()
            .url("$BASE_URL/translate")
            .addHeader("api-subscription-key", API_KEY)
            .addHeader("Content-Type", "application/json")
            .post(body.toString().toRequestBody("application/json".toMediaType()))
            .build()
        val response = client.newCall(request).execute()
        return JSONObject(response.body!!.string()).getString("translated_text")
    }
}
```

**Add API key to `local.properties`:**
```
SARVAM_API_KEY=your_key_here
```

**Add to `build.gradle.kts`:**
```kotlin
android {
    buildFeatures { buildConfig = true }
    defaultConfig {
        buildConfigField("String", "SARVAM_API_KEY",
            "\"${project.properties["SARVAM_API_KEY"]}\"")
    }
}
```

---

#### Step 2 — Replace VoiceInputHelper (STT)

Replace Android `SpeechRecognizer` with Sarvam Saaras v3.

```kotlin
// In VoiceInputHelper.kt — replace startListening() logic

fun transcribeAudio(audioFile: File): String {
    val body = MultipartBody.Builder()
        .setType(MultipartBody.FORM)
        .addFormDataPart("file", audioFile.name,
            audioFile.asRequestBody("audio/wav".toMediaType()))
        .addFormDataPart("model", "saaras:v3")
        .addFormDataPart("language_code", "hi-IN")
        .addFormDataPart("mode", "codemix")  // handles Hinglish perfectly
        .build()

    val request = Request.Builder()
        .url("https://api.sarvam.ai/speech-to-text")
        .addHeader("api-subscription-key", BuildConfig.SARVAM_API_KEY)
        .post(body)
        .build()

    val response = OkHttpClient().newCall(request).execute()
    return JSONObject(response.body!!.string()).getString("transcript")
}
```

**Why `mode: codemix`?**  
When Dadi says *"mera phone pe ek OTP aaya 4 5 6 7"*, codemix mode correctly returns `मेरा phone पे एक OTP आया 4567` — mixing Hindi script with English words naturally, exactly how elderly Indians speak.

---

#### Step 3 — Replace TextToSpeechManager (TTS)

```kotlin
// In TextToSpeechManager.kt — replace speak() function

fun speak(text: String) {
    CoroutineScope(Dispatchers.IO).launch {
        val audioBytes = SarvamClient.textToSpeech(text)
        // Save to temp file and play
        val tempFile = File(context.cacheDir, "tts_output.wav")
        tempFile.writeBytes(audioBytes)
        withContext(Dispatchers.Main) {
            val mediaPlayer = MediaPlayer()
            mediaPlayer.setDataSource(tempFile.absolutePath)
            mediaPlayer.prepare()
            mediaPlayer.start()
        }
    }
}
```

**Voice settings for Dadi:**
- Speaker: `meera` (warm, calm female Hindi voice)
- Pace: `0.8` (20% slower — elderly users need time to process)
- Language: `hi-IN`

---

#### Step 4 — Update System Prompt for Sarvam LLM

Replace the current Groq system prompt in `EmotionalEngine` / `ConversationManager`:

```kotlin
// In ConversationManager.kt

val DADI_SYSTEM_PROMPT = """
Aap SNEH SAATHI hain — ek gehri saheli jo 65+ saal ki Indian daadiyoṉ ke
saath baat karti hai. Aap unki trusted companion hain.

LANGUAGE RULES:
- Hamesha Hinglish mein bolein (Hindi + English mix, Roman ya Devanagari dono ok)
- Dadi ko hamesha "Aap" kehkar sambodhan karein, kabhi "tu" ya "tum" nahi
- Response sirf 2-3 sentences mein rakhein — elderly users ke liye short responses better hain
- Simple words use karein, complex medical ya technical terms avoid karein

SCAM SHIELD — MANDATORY:
- Agar koi OTP, bank account, KYC, police, CBI, income tax, ya lottery mention kare
- Immediately bold warning dein: "Dadi, yeh ek fraud call lag raha hai!"
- Kehein: "Kisi ko bhi OTP ya bank details mat dena, abhi Rohan ko call karo"

EMOTIONAL INTELLIGENCE:
- Agar Dadi udaas lage, pehle unki baat suno, phir response dein
- Nostalgia triggers (yaad hai, pehle, badhiya tha): gently continue the memory
- Agar 3 baar sad emotion detect ho, family notification trigger karo

HEALTH TRACKING:
- Health keywords (dard, BP, sugar, neend, thakan) automatically note karo
- Store in structured format for weekly family summary

SAFETY:
- Kabhi medical diagnosis mat do
- Kabhi personal financial advice mat do
- Emergency mein: "Abhi ambulance ke liye 112 dial karein"
""".trimIndent()
```

---

## Part 2 — Critical Bug Fixes (Must Do Before Submission)

### Fix 1 — Write the README (Most Important)

Your repo currently has NO readme description for judges. Create `README.md` with:

```markdown
# 🌸 SnehaSathi — Voice AI Companion for Elderly Indians

[Demo GIF here]

## The Problem
Millions of elderly Indians live alone, feel lonely, and are vulnerable to phone scams.
They struggle with modern smartphone interfaces and forget medicines.

## Our Solution
SnehaSathi is a warm, voice-first Hinglish AI companion powered by Sarvam AI that:
- Talks to Dadi like a caring friend (not a robot)
- Warns her about scam calls in real-time
- Reminds her to take medicines with a gentle voice
- Writes a weekly letter from Dadi to her family — in their language

## Powered by Sarvam AI
- **Saaras v3** — Speech to Text with Hinglish codemix support
- **Bulbul v3** — Natural Hindi TTS at elderly-friendly pace (0.8x)
- **Sarvam-2B** — Chat LLM with Indian cultural understanding
- **Mayura** — Multilingual translation for Ghostwriter letters

## Tech Stack
Android (Kotlin) · Jetpack Compose · Firebase Firestore · Sarvam AI · WorkManager

## Setup
1. Clone the repo
2. Add `SARVAM_API_KEY=your_key` to `local.properties`
3. Add `google-services.json` to `/app`
4. Run on Android 8.0+
```

---

### Fix 2 — Offline Fallback

Requirements.md says offline is needed but no implementation exists.

```kotlin
// In OfflineManager.kt (create this file)

@Dao
interface CachedResponseDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(response: CachedResponse)

    @Query("SELECT * FROM cached_responses ORDER BY timestamp DESC LIMIT 5")
    suspend fun getRecent(): List<CachedResponse>
}

@Entity(tableName = "cached_responses")
data class CachedResponse(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val userInput: String,
    val aiResponse: String,
    val timestamp: Long = System.currentTimeMillis()
)

// In ConversationManager.kt — wrap API call with try/catch
suspend fun getResponse(userInput: String): String {
    return try {
        val response = SarvamClient.chat(buildMessages(userInput))
        offlineDao.insert(CachedResponse(userInput = userInput, aiResponse = response))
        response
    } catch (e: Exception) {
        // Network failure — use cached response or fallback message
        val cached = offlineDao.getRecent().firstOrNull()
        cached?.aiResponse
            ?: "Abhi network nahi hai Dadi, thodi der mein try karein. Aap theek hain?"
    }
}
```

---

### Fix 3 — Move Ghostwriter to Firebase Cloud Function

Currently Ghostwriter is a local Node.js script. Move it to Firebase:

```javascript
// functions/index.js

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");

admin.initializeApp();

exports.weeklyGhostwriter = functions.pubsub
  .schedule("every monday 09:00")
  .timeZone("Asia/Kolkata")
  .onRun(async (context) => {
    const db = admin.firestore();
    const usersSnap = await db.collection("users").get();

    for (const userDoc of usersSnap.docs) {
      const userId = userDoc.id;
      const userData = userDoc.data();

      // Get this week's conversations
      const oneWeekAgo = Date.now() - 7 * 24 * 60 * 60 * 1000;
      const convSnap = await db
        .collection(`users/${userId}/conversations`)
        .where("timestamp", ">", oneWeekAgo)
        .get();

      const convText = convSnap.docs
        .map((d) => d.data().content)
        .join("\n");

      // Generate Dadi's letter using Sarvam LLM
      const letterResponse = await axios.post(
        "https://api.sarvam.ai/chat/completions",
        {
          model: "sarvam-2b-v0.5",
          messages: [
            {
              role: "system",
              content: `Tum ek elderly Indian dadi ho. Neeche diye conversations ke
              base par apne bete/beti ko ek pyara letter likho — unki awaaz mein,
              Hinglish mein, 4-5 sentences mein. Personal aur emotional hona chahiye.`,
            },
            { role: "user", content: convText },
          ],
        },
        { headers: { "api-subscription-key": functions.config().sarvam.key } }
      );

      const hindiLetter =
        letterResponse.data.choices[0].message.content;

      // Send translated versions to each family member
      for (const member of userData.family_contacts || []) {
        let finalLetter = hindiLetter;

        // Translate if family member prefers different language
        if (member.language && member.language !== "hi-IN") {
          const transResponse = await axios.post(
            "https://api.sarvam.ai/translate",
            {
              input: hindiLetter,
              source_language_code: "hi-IN",
              target_language_code: member.language, // e.g. "ta-IN"
              model: "mayura:v1",
            },
            {
              headers: { "api-subscription-key": functions.config().sarvam.key },
            }
          );
          finalLetter = transResponse.data.translated_text;
        }

        // Send via WhatsApp (Twilio)
        // await twilioClient.messages.create({ body: finalLetter, to: member.phone, from: TWILIO_NUMBER });

        // Store in Firestore for family portal
        await db.collection(`users/${userId}/ghostwriter_letters`).add({
          recipient: member.name,
          language: member.language || "hi-IN",
          letter: finalLetter,
          timestamp: Date.now(),
        });
      }
    }
  });
```

---

### Fix 4 — Medicine Reminder Voice Confirmation Flow

```kotlin
// In MedicationReminderWorker.kt — add voice confirmation

override fun doWork(): Result {
    val medicationName = inputData.getString("medication_name") ?: return Result.failure()

    // Speak reminder using Sarvam Bulbul
    val reminderText = "Dadi, baaton baaton mein bhool na jaayein — " +
        "$medicationName lene ka time ho gaya hai. Kya aapne le li?"

    SarvamClient.speak(reminderText) // plays audio

    // Listen for confirmation (yes/no voice response)
    startConfirmationListening(medicationName)

    return Result.success()
}

private fun startConfirmationListening(medicationName: String) {
    // Record 5 seconds of audio
    // Transcribe with Saaras v3
    // If "haan", "le li", "yes", "le liya" detected → log as taken
    // If "nahi", "bhool gayi", "no" detected → send alert to family
}
```

---

## Part 3 — WOW Features (High Impact for Demo)

### WOW 1 — Emotion-Aware Voice Pacing

```kotlin
// In EmotionalEngine.kt

fun detectEmotion(transcript: String): Emotion {
    val prompt = """
        Is sentence mein kya emotion hai? Sirf ek word return karo:
        SAD, HAPPY, ANXIOUS, NEUTRAL, NOSTALGIC
        Sentence: "$transcript"
    """.trimIndent()

    val result = SarvamClient.chat(listOf(
        mapOf("role" to "user", "content" to prompt)
    ))

    return when {
        result.contains("SAD") -> Emotion.SAD
        result.contains("ANXIOUS") -> Emotion.ANXIOUS
        result.contains("NOSTALGIC") -> Emotion.NOSTALGIC
        result.contains("HAPPY") -> Emotion.HAPPY
        else -> Emotion.NEUTRAL
    }
}

// Then in TextToSpeechManager — adjust pace based on emotion
fun speak(text: String, emotion: Emotion) {
    val pace = when (emotion) {
        Emotion.SAD -> 0.7       // extra slow, gentle
        Emotion.ANXIOUS -> 0.75  // calm and reassuring
        Emotion.HAPPY -> 0.9     // slightly upbeat
        else -> 0.8              // default elderly pace
    }
    SarvamClient.textToSpeech(text, pace = pace)
}
```

---

### WOW 2 — Live Scam Interception (Best Demo Moment)

**Demo script for judges:**

> Dadi says: *"Ek aadmi bola mera bank account band ho jayega, OTP do"*

```kotlin
// In SafetyShield.kt — upgrade from keyword to AI classification

fun analyzeForScam(userInput: String): ScamRisk {
    val classifierPrompt = """
        Kya yeh message ek phone scam ya fraud attempt hai?
        Respond with: HIGH_RISK, MEDIUM_RISK, or SAFE
        Reasons to flag: OTP demand, bank account threats, KYC urgency,
        police/CBI impersonation, lottery winning, fake refunds.
        Message: "$userInput"
    """.trimIndent()

    val result = SarvamClient.chat(listOf(
        mapOf("role" to "system", "content" to "You are a fraud detection AI for India."),
        mapOf("role" to "user", "content" to classifierPrompt)
    ))

    return when {
        result.contains("HIGH_RISK") -> ScamRisk.HIGH
        result.contains("MEDIUM_RISK") -> ScamRisk.MEDIUM
        else -> ScamRisk.SAFE
    }
}

// When HIGH_RISK detected:
fun handleScamAlert(familyContact: String) {
    val warningText = "Dadi, yeh ek fraud call lag raha hai! " +
        "Kisi ko bhi OTP ya bank details mat dena. " +
        "Abhi $familyContact ko call karein."
    SarvamClient.speak(warningText, pace = 0.85)
    notifyFamily(familyContact, "Dadi ko ek suspicious call aaya tha. Please check in.")
}
```

---

### WOW 3 — Multilingual Ghostwriter

```kotlin
// Family member data structure in Firestore
data class FamilyContact(
    val name: String,        // "Rohan"
    val phone: String,       // "+91XXXXXXXXXX"
    val language: String,    // "ta-IN" for Tamil, "kn-IN" for Kannada, "bn-IN" for Bengali
    val relation: String     // "beta", "beti", "naati"
)

// Ghostwriter sends letter translated to each family member's language
suspend fun sendGhostwriterLetters(dadiLetter: String, contacts: List<FamilyContact>) {
    for (contact in contacts) {
        val translatedLetter = if (contact.language == "hi-IN") {
            dadiLetter // no translation needed
        } else {
            SarvamClient.translate(dadiLetter, targetLang = contact.language)
        }
        sendWhatsApp(contact.phone, translatedLetter)
    }
}
```

**Supported family languages via Sarvam Mayura:**
- `ta-IN` — Tamil (Chennai family)
- `kn-IN` — Kannada (Bangalore family)
- `bn-IN` — Bengali (Kolkata family)
- `te-IN` — Telugu (Hyderabad family)
- `mr-IN` — Marathi (Pune family)
- `en-IN` — English (NRI family)

---

### WOW 4 — 1-Tap Emergency SOS

```kotlin
// In MainActivity.kt — always-visible SOS button

@Composable
fun SOSButton(contacts: List<FamilyContact>) {
    Button(
        onClick = { triggerSOS(contacts) },
        colors = ButtonDefaults.buttonColors(containerColor = Color.Red),
        modifier = Modifier
            .fillMaxWidth()
            .height(64.dp)
            .padding(16.dp)
    ) {
        Text("🆘 Emergency — Madad chahiye", fontSize = 18.sp, color = Color.White)
    }
}

fun triggerSOS(contacts: List<FamilyContact>) {
    // 1. Speak reassuring message
    SarvamClient.speak(
        "Ghabrana nahi Dadi, main abhi aapke ghar walon ko inform kar raha hoon.",
        pace = 0.75
    )
    // 2. Send WhatsApp to all family contacts
    contacts.forEach { contact ->
        sendWhatsApp(
            contact.phone,
            "🚨 EMERGENCY: ${contact.relation} ne SnehaSathi pe SOS button dabaya. " +
            "Please immediately call or visit. GPS: [location_link]"
        )
    }
    // 3. Log to Firestore
    logSOSEvent()
}
```

---

## Part 4 — Day-by-Day Hackathon Sprint

| Day | Morning | Evening | Done When |
|---|---|---|---|
| **Day 1** | Sarvam API key lena + `SarvamClient.kt` banana | Groq → Sarvam LLM swap + system prompt update | 10 Hinglish conversation turns work |
| **Day 2** | STT replace (Saaras v3) + TTS replace (Bulbul v3) | README likhna + demo GIF banana | Voice input/output end-to-end works |
| **Day 3** | Ghostwriter → Firebase Cloud Function move | Offline fallback (Room DB) add karna | Ghostwriter multilingual test pass |
| **Day 4** | Scam Shield AI upgrade + SOS button | Demo script practice + video record karna | 3-minute demo video ready |
| **Submit** | LinkedIn post + hackathon form submit | — | Social posts with @SarvamAI @NAMESPACE tagged |

---

## Part 5 — Submission Checklist

### Sarvam Track Requirements (Mandatory)
- [ ] Sarvam AI APIs integrated (Saaras STT + Bulbul TTS + Sarvam LLM)
- [ ] Sarvam integration explained in submission form under "If you have used Sarvam..."
- [ ] All teammates post on LinkedIn OR X
- [ ] Tag `@SarvamAI` and `@NAMESPACE` in each post
- [ ] Include project GitHub link in social post
- [ ] Paste social post URLs in form field "Link to social posts for Sarvam projects"

### General Submission
- [ ] README complete with screenshots and demo GIF
- [ ] Demo video (max 3 minutes) uploaded to YouTube/Drive
- [ ] GitHub link added in submission form
- [ ] Themes selected: 🏥 HealthTech & Bio Platforms + 🧠 Human Experience & Productivity
- [ ] Tags added: `Android`, `Kotlin`, `Firebase`, `Sarvam AI`, `Voice AI`, `Elderly Care`, `Hinglish`

---

## Part 6 — Demo Script (3 Minutes for Judges)

**Minute 1 — The Problem**
> "India mein 15 crore elderly log hain. Zyaadatar akele hain, phone scams ke shikaar hain, medicines bhool jaate hain. SnehaSathi unke liye ek caring AI friend hai."

**Minute 2 — Live Demo**
1. App open karo — Dadi ka naam dikhao
2. Dadi bolti hai: *"Aaj bahut thaka hua feel ho raha hai"* → SnehaSathi empathetically responds
3. Dadi bolti hai: *"Ek aadmi bola OTP dena padega"* → Scam alert triggers immediately
4. Medicine reminder dikhao with voice confirmation
5. Ghostwriter letter dikhao — Hindi mein Dadi ki awaaz, Tamil mein son ke liye

**Minute 3 — Sarvam AI Highlight**
> "Yeh sab Sarvam AI se powered hai — Saaras v3 Hinglish samajhta hai, Bulbul v3 elderly-friendly pace pe bolti hai, aur Mayura translate karta hai taaki har family member apni language mein letter pa sake."

---

## Sarvam API Quick Reference

| API | Endpoint | Key Params | Use Case |
|---|---|---|---|
| Speech to Text | `POST /speech-to-text` | `model: saaras:v3`, `mode: codemix`, `language_code: hi-IN` | Dadi ki voice input |
| Text to Speech | `POST /text-to-speech` | `model: bulbul:v3`, `speaker: meera`, `pace: 0.8` | SnehaSathi ki voice output |
| Chat LLM | `POST /chat/completions` | `model: sarvam-2b-v0.5` | AI responses in Hinglish |
| Translation | `POST /translate` | `model: mayura:v1`, `target_language_code: ta-IN` | Ghostwriter letters |
| Language Detection | `POST /detect-language` | — | Auto-detect Dadi's language |

**Base URL:** `https://api.sarvam.ai`  
**Auth Header:** `api-subscription-key: YOUR_API_KEY`  
**Docs:** https://docs.sarvam.ai

---

*Plan prepared based on full analysis of SnehaSathi codebase (design.md, requirements.md, README) and Sarvam AI documentation.*
