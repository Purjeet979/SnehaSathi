# 🌸 Sneh Saathi — A Voice Companion for Elderly Care

**Sneh Saathi** is a warm, voice-first AI companion designed for elderly Indian users, especially those living alone.  
It focuses on **emotional well-being, safety, memory, and family connection**, using simple Hinglish conversations instead of complex interfaces.

> *"Technology should not replace humans — it should bring them closer."*  

---

## 🚀 Key Features

Sneh Saathi is designed from the ground up based on a deep analysis of Indian elderly pain points. It is an **offline-first, emotionally intelligent companion** with a highly accessible UI/UX.

### ✨ The UI/UX Paradigm Shift
- **The 3 Laws of Sneh Saathi UX:** 
  1. *One Screen, One Job* 
  2. *Every Error Must Self-Resolve* 
  3. *The App Must Never Feel Like Technology*
- **4-Button Radial Home Screen:** We discarded complex tab bars for a hyper-legible 4-button layout (Talk, Meds, Family, Security) anchored by a massive SOS button.
- **Voice-First Onboarding:** No emails, no OTPs, no typing. The app asks for the user's name, family members, and medications entirely through a 3-step voice conversation.
- **Accessible Aesthetics:** Implemented a high-contrast, warm cream palette (`#FFF8F0`) with large, 22sp minimum typography and 1.5x line heights optimized for aging eyes.
- **Breathing Mic Interaction:** A color-shifting, pulsing microphone button that acts as a visual anchor and speaks its current state (Listening, Thinking) aloud.

### 🌟 Standout Capabilities
- **Rooh Pehchaan (Emotional Subtext Detection):** Analyzes speech energy, speaking rate, and pitch variance to detect if Dadi is sad, anxious, or confused, automatically shifting the AI's response tone to match.
- **Parivaar Bridge (Silent Family Dashboard):** Generates a daily, non-invasive summary of Dadi's emotional state and interactions, designed to be piped directly to the family's WhatsApp.
- **Bhajan & Kahaani (Goodnight Mode):** An offline content library that can proactively play familiar bhajans if Dadi is inactive around 9 PM.
- **Aaj Ka Din (Morning Ritual):** A background worker that wakes up at 7:00 AM to proactively greet Dadi with "Jai Shri Krishna" and start a gentle morning conversation.
- **Yaadein (Photo Memories):** A simplified, 1-tap camera interface designed for Dadi to take photos which the AI then weaves into beautiful Hinglish memory stories.
- **Swaasthya Baatein (Conversational Health Log):** Silently extracts health complaints (e.g., "Mera ghutna dard kar raha hai") from casual conversation and logs them to a database to detect patterns over time.

---

## 🧩 Architecture & Technology Stack

Sneh Saathi has been migrated to a robust, modern **Clean Architecture** (Data, Domain, Presentation) optimized for offline resilience and privacy.

### 📱 Frontend (Android)
- **Kotlin & Jetpack Compose:** Fully declarative UI using modern Material 3 guidelines adapted for extreme accessibility.
- **Accompanist Permissions:** Seamless, localized permission requests for Audio, Camera, and Call/SMS (for the SOS feature).
- **Hilt (Dependency Injection):** For clean, decoupled module management.

### ⚙️ Core Systems (Offline-First)
- **Room Database:** Local persistence layer caching `Memories`, `Conversations`, `Medications`, and `HealthLogs`.
- **LiteRT (TensorFlow Lite):** Runs `embedding_model.tflite` directly on-device to generate vector embeddings for the local memory retrieval (RAG) pipeline.
- **DataStore:** Replaced SharedPreferences for type-safe, reactive storage of Dadi's preferences (Voice Speed, Contacts).
- **WorkManager:** Guaranteed background execution for `MedicationReminderWorker`, `MorningRitualWorker`, and `ParivaarBridgeWorker`—even after device reboots.
- **ConnectivityObserver:** Uses Kotlin `Flow` to detect network drops and smoothly transition the app into a fully offline fallback mode.

### 🤖 AI & NLP
- **Sarvam AI (Cloud):** Highly-tuned LLM specialized in authentic Indian Hinglish context.
- **Offline TTS Manager:** Android's native Text-to-Speech specifically initialized for `hi-IN` with optimized pitch and speech rates for a natural, elderly-friendly cadence.
- **On-Device RAG (Retrieval-Augmented Generation):** Matches Dadi's current prompt against her `MemoryEntity` table using cosine similarity on the LiteRT embeddings.

---

## 🛡️ Scam Shield Upgrade
Financial scams are the #1 fear for elderly smartphone users in India. 
- **Pattern & Context Scoring:** Upgraded from simple keyword matching to a weighted scoring system that analyzes the urgency and context of messages (e.g., "UPI", "Bank KYC", "Urgent").
- **Visual & Audio Alarms:** Triggers a high-contrast soft-red `ScamWarningDialog` that immediately advises Dadi to hang up and contact her family.

---

## 🟢 Google Technology Usage (Mandatory Requirement)
- **Firebase Firestore:** Backup layer for memories and family summaries.
- **Firebase Background Services.**
- **TensorFlow Lite (LiteRT):** Core to the on-device memory embedding engine.

---

## 🎥 Demo & Links

- **GitHub Repository:**  
  https://github.com/Purjeet979/HackWins

- **Demo Video (3 minutes):**  
  [Google Drive Link](https://drive.google.com/drive/folders/17j_PTlFP8RmSxmHQ0Uu3O9PmVIW0VLa6?usp=sharing)

---

## 👥 Team

- **Developer:** Purjeet  
- **Project:** Hackathon Submission
