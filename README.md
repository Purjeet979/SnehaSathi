<img width="4320" height="1440" alt="hh26 main poster 2 with sponsors 3x1 (4320 x 1440 px) (2)" src="https://github.com/user-attachments/assets/c698b2cd-da84-4cb0-9276-125c6a7244aa" />

# 🌸 Sneh Saathi

> A voice-first AI companion, safety shield, and medication guide designed to keep independent Indian elders safe, healthy, and connected to their families.

---

## 📌 Problem & Domain

In India, millions of senior citizens live independently while their children work in different cities or countries. These elders face three major challenges:
1. **Digital Isolation**: Standard modern applications are built for tech-savvy users, featuring small fonts, complex onboarding processes, and English-only menus.
2. **Health Negligence & Reminders**: Forgetting critical medications (like hypertension or diabetes pills) is common. Traditional alarm systems are easily snoozed or dismissed.
3. **Digital & Financial Scams**: Seniors are the primary target for phishing, fake bills, and digital arrest threats, often lacking the tools to verify scam messages.

**Themes Selected (at least one):**
- [x] Human Experience & Productivity  
- [ ] Climate & Sustainability Systems  
- [x] HealthTech & Bio Platforms  
- [ ] Learning & Knowledge Systems  
- [ ] Work, Finance & Digital Economy  
- [ ] Infrastructure, Mobility & Smart Systems  
- [x] Trust, Identity & Security  
- [ ] Media, Social & Interactive Platforms  
- [ ] Public Systems, Governance and Civic Tech  
- [ ] Developer Tools & Software Infrastructure  

---

## 🎯 Objective

Sneh Saathi serves **elderly Indian citizens** who live independently and their **worried family members** who want to ensure their safety from afar.

- **The Target Users**: Indian senior citizens who may not speak English fluently, prefer speaking over typing, or struggle with complex mobile layouts.
- **The Pain Point**: A lack of dedicated, empathetic tools that protect elders from cyber threats, keep track of daily medications, and share status reports with children without violating the elder's privacy.
- **The Value**: Sneh Saathi acts as a warm, dialect-fluent voice companion that speaks their language (Hindi, Marathi, Gujarati, etc.), monitors safety and health, blocks scams, and keeps the family in the loop.

---

## 🧠 Team & Approach

### Team Name:  
`Sneh Saathi`

### Team Members:  
- **Purjeet** (GitHub: [@Purjeet979](https://github.com/Purjeet979) | Developer & Architect)

### Your Approach:
* **Empathy-Driven Design**: Instead of packing the app with text and tabs, we formulated the **3 Laws of Sneh Saathi UX**: *One Screen, One Job*, *Every Error Must Self-Resolve*, and *The App Must Never Feel Like Technology*. The core navigation is a scroll-free radial layout anchored by a prominent central button.
* **Dialect-First AI**: Standard translation APIs fail to capture the warmth of regional Indian dialects. We integrated **Sarvam AI**'s speech models, enabling the companion to converse fluently in regional scripts (Hindi, Marathi, Gujarati, Punjabi, Bihari, and Haryanvi).
* **Robust Hardware Integration**: Budget Android devices (Redmi, Samsung) frequently throttle background tasks and block silent permissions. We bypassed these limitations by:
  - Designing a **Relative Noise-Floor Calibration** routine for STT that adapts to local ambient noise (fans, traffic).
  - Writing a native Kotlin **MethodChannel** to dispatch silent emergency SMS with coordinates, fallbacking to the system composer if needed.
  - Adding a **Completer with safety timeouts** to synchronize speech playbacks on physical TTS systems.

---

## 🛠️ Tech Stack

### Core Technologies Used:
- **Frontend**: Flutter & Dart (State Management via Riverpod)
- **Backend & Cloud**: Firebase Firestore, Firebase Storage
- **Database**: Drift (SQLite) for on-device persistence
- **APIs & LLMs**: Sarvam AI (Text-to-Speech & Speech-to-Text)
- **Background Jobs**: Android WorkManager (Periodic sync, medication workers)

### Additional Technologies Used (Optional):
- [x] AI / ML (Sarvam Llama-based Mayura & Saaras Models)  
- [ ] Web3 / Blockchain  
- [x] Cyber Security (Saavdhan Scam Shield Rules & Analysis) 
- [x] Cloud (Firebase Infrastructure & GitHub Actions Workflows)  

---

## 🏆 Sponsored Track (Optional)

Select if your project participates in any track:

- [ ] **Expo Track** – Built using Expo  
- [ ] **Neo4j Track** – Uses AuraDB as primary database  
- [ ] **Base44 Track** – Prototype/Final Product built using Base44  

---

## ✨ Key Features

- 🎤 **Zero-Latency Voice Companion**: Converses naturally in 6 regional languages (Hindi, Marathi, Gujarati, Punjabi, Bihari, Haryanvi). Bypasses loading screens by streaming Text-to-Speech sentence-by-sentence.
- 💊 **Dawai Saathi (Smart Medication Tracker)**: Reminds elders about pills. Understands real-world answers like *"baad mein"* or *"thodi der mein"* and schedules a follow-up re-prompt instead of marking it complete.
- 🛡️ **Saavdhan (Scam Shield)**: Real-time scan of suspicious text messages, notifications, or voice clips using hybrid AI + rule-based checks, triggering visual red alerts and audio warnings.
- 🚨 **Native SOS (Kotlin MethodChannel)**: A physical/virtual emergency trigger. Instantly gets the device's GPS coordinates and dispatches a silent SMS to the emergency contacts, fallbacking to the native SMS app if needed.
- 🔒 **Raat Ki Safety Check**: A guided regional voice checklist (closing doors, windows, gas knob check) to keep elders safe and give them peace of mind at night.
- 🕊️ **Parivaar Bridge & GitHub Actions Automation**: 
  - **App-Based**: Single-tap daily update forwarding via WhatsApp.
  - **Cloud-Based**: A scheduled **GitHub Actions Cron Workflow** runs every Sunday, fetches weekly summaries from Firestore, and automatically sends a weekly digest to children using the **WhatsApp Cloud API**.

---

## 📽️ Demo & Deliverables

- **Demo Video Link (Mandatory):** [Google Drive Demo Video](https://drive.google.com/file/d/1ex35QU-pGOgB0uwNVdA2_kaKEmGRx_He/view?usp=sharing)
- **Deployment Link (Recommended):** [GitHub Repository Link](https://github.com/Purjeet979/SnehaSathi)
- **Pitch Deck / PPT (Optional):** [Paste link]  

---

## ✅ Tasks & Bonus Checklist

- [ ] All team members completed the mandatory social task  
- [ ] Bonus Task 1 – Badge sharing  
- [ ] Bonus Task 2 – Blog/article  

---

## 🧪 How to Run the Project

### Requirements:
- **Flutter SDK**: `>=3.3.0`
- **Dart**: `>=3.3.0`
- **Android Studio / VS Code** with Flutter extensions installed.
- **Sarvam AI Subscription Key** (For TTS & STT capabilities).

### Local Setup:
1. Clone the repository:
   ```bash
   git clone https://github.com/Purjeet979/SnehaSathi.git
   cd SnehaSathi
   ```
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Run the project (ensure your physical Android/iOS device or emulator is connected):
   ```bash
   flutter run --dart-define=SARVAM_API_KEY=your_sarvam_api_key_here
   ```

---

## 🧬 Future Scope

- 🗣️ **More Regional Dialects**: Expanding to South Indian languages (Tamil, Telugu, Kannada, Malayalam).
- 🧠 **TensorFlow Lite (LiteRT)**: Moving the scam detection engine fully offline via localized TFLite models, making it secure and zero-cost.
- 🩺 **IoT Wearables Integration**: Automatically pulling heart-rate or fall-detection data from smartwatches to trigger the native SOS coordinates message automatically.

---

## 📎 Resources / Credits

- **Sarvam AI**: For providing high-quality regional Indian speech and language LLMs.
- **Drift (SQLite)**: For high-performance offline database persistence.
- **WorkManager**: For reliable background job scheduling on Android.

---

## 🏁 Final Words

Building Sneh Saathi was an incredibly meaningful journey. Integrating real-time speech processing and ensuring compatibility with budget devices brought several engineering challenges (from Android audio focus bugs to MIUI TTS speech interruptions). Ultimately, seeing the app run smoothly on a physical phone and knowing it can help protect our elders was the greatest breakthrough. 🧡
