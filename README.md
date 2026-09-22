# 🌸 Sneh Saathi

Sneh Saathi is a voice-first Flutter application designed to help elderly people live more safely and independently. It provides regional-language assistance, medication reminders, scam protection, emergency support, and a simple way for families to stay connected.

## Overview

Many senior citizens find modern mobile applications difficult to use because of complex interfaces, small text, English-first experiences, and limited accessibility. Sneh Saathi focuses on a simple, conversational experience built around voice and regional Indian languages.

The application helps users with:

- Everyday voice-based assistance
- Medication reminders and follow-up prompts
- Suspicious message and scam detection
- Emergency SOS support
- Night-time safety checklists
- Family updates and weekly summaries
- Offline-friendly local data persistence

## Key Features

### 🎤 Voice Companion

Interact with the application using voice instead of typing. Sneh Saathi supports regional-language conversations and is designed for users who may not be comfortable with English or complex app interfaces.

### 💊 Medication Reminders

The medication tracker reminds users to take their medicines and can handle natural responses such as “later” or “after some time” by scheduling a follow-up reminder.

### 🛡️ Scam Shield

Saavdhan analyses suspicious messages, notifications, and voice content using a combination of rules and AI-assisted analysis. It provides clear warnings to help users identify potential scams.

### 🚨 Emergency SOS

The SOS feature can access the device location and notify emergency contacts through the native Android integration. A fallback flow is provided when silent messaging is not available on a device.

### 🌙 Night Safety Check

A guided checklist helps users verify important things such as doors, windows, and gas appliances before going to sleep.

### 👨‍👩‍👧 Family Updates

Family members can receive important updates and summaries while keeping the experience simple for elderly users. The Parivaar Bridge module supports scheduled weekly summaries and WhatsApp delivery.

## Technology Stack

- **Frontend:** Flutter and Dart
- **State Management:** Riverpod
- **Cloud Services:** Firebase Firestore and Firebase Storage
- **Local Database:** Drift with SQLite
- **Speech and Language:** Sarvam AI speech-to-text and text-to-speech APIs
- **Background Processing:** Android WorkManager
- **Native Integration:** Android Kotlin MethodChannel
- **Automation:** GitHub Actions

## Project Structure

```text
SnehaSathi/
├── android/              # Android platform code and native integrations
├── ios/                  # iOS platform configuration
├── lib/                  # Flutter application source code
├── assets/               # Images and other application assets
├── parivaar-bridge/      # Weekly family summary service
├── test/                 # Flutter tests
├── pubspec.yaml          # Flutter dependencies and project configuration
└── README.md
```

## Requirements

Before running the project, install the following:

- Flutter SDK `>=3.3.0`
- Dart SDK `>=3.3.0`
- Android Studio or VS Code with Flutter extensions
- An Android or iOS device, or an emulator
- Firebase project configuration
- Sarvam AI API key for speech features

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/Purjeet979/SnehaSathi.git
cd SnehaSathi
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure Firebase

Add the Firebase configuration files for the platform you want to run:

- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

Make sure Firebase services used by the application are enabled in your Firebase project.

### 4. Configure the Sarvam AI key

Pass the API key at runtime using `--dart-define`:

```bash
flutter run --dart-define=SARVAM_API_KEY=your_sarvam_api_key_here
```

Do not commit API keys or service-account credentials to the repository.

## Running the Application

Run the application on a connected device or emulator:

```bash
flutter run --dart-define=SARVAM_API_KEY=your_sarvam_api_key_here
```

For a release APK:

```bash
flutter build apk --release --dart-define=SARVAM_API_KEY=your_sarvam_api_key_here
```

## Parivaar Bridge

The `parivaar-bridge` directory contains the service responsible for generating and sending weekly family summaries.

For setup and environment variables, refer to [`parivaar-bridge/README.md`](parivaar-bridge/README.md).

The service uses environment variables and GitHub Actions secrets for credentials. Never hardcode Firebase, Sarvam AI, or WhatsApp access tokens in source code.

## Privacy and Security

- Sensitive credentials should be stored in environment variables or GitHub Secrets.
- Firebase security rules should be configured before using the application in production.
- Raw conversations should not be uploaded unless the user has explicitly enabled the required functionality.
- Location and emergency permissions should be requested transparently and used only for safety features.
- Keep service-account files and local configuration files out of version control.

## Future Improvements

- Add support for more Indian languages and dialects
- Improve offline scam detection with on-device machine learning
- Add smartwatch and wearable integrations
- Expand accessibility options such as larger text and high-contrast themes
- Add richer family dashboards and health insights
- Improve automated testing across Android and iOS devices

## Contributing

Contributions are welcome. To contribute:

1. Fork the repository.
2. Create a feature branch.
3. Make your changes and add tests where appropriate.
4. Run the project and verify the changes locally.
5. Open a pull request with a clear description of the changes.

## License

No license has been added to this repository yet. Until a license is provided, all rights are reserved by the repository owner.

## Acknowledgements

- [Flutter](https://flutter.dev/)
- [Firebase](https://firebase.google.com/)
- [Sarvam AI](https://www.sarvam.ai/)
- [Drift](https://drift.simonbinder.eu/)
- [Android WorkManager](https://developer.android.com/topic/libraries/architecture/workmanager)
