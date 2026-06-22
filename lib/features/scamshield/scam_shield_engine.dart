import '../../core/tts/text_to_speech_manager.dart';

class ScamShieldEngine {
  final TextToSpeechManager _ttsManager;

  ScamShieldEngine(this._ttsManager);

  static const List<String> _scamKeywords = [
    'otp', 'bank', 'police', 'lottery', 'password', 'cvv', 'pin', 'account block'
  ];

  bool scanInput(String input) {
    final lowerInput = input.toLowerCase();
    for (final keyword in _scamKeywords) {
      if (lowerInput.contains(keyword)) {
        return true;
      }
    }
    return false;
  }

  Future<void> triggerWarning() async {
    final warningText = "Dadi, savdhaan rahein! Ye ek fraud ho sakta hai. Apna OTP, password, ya bank details kisi ko na dein.";
    await _ttsManager.speakFast(warningText, emotion: Emotion.anxious);
  }
}
