import 'package:flutter_tts/flutter_tts.dart';

enum Emotion { neutral, sad, anxious, nostalgic, happy }

class TextToSpeechManager {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isReady = false;

  TextToSpeechManager() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("hi-IN");
    await _flutterTts.setSpeechRate(0.4); // Slower for Dadi
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    _isReady = true;
  }

  Future<void> speakFast(String text, {String language = "hi", Emotion emotion = Emotion.neutral, Function? onComplete}) async {
    if (!_isReady) return;
    if (text.trim().isEmpty) {
      onComplete?.call();
      return;
    }

    final targetLocale = (language == "en") ? "en-IN" : "hi-IN";
    await _flutterTts.setLanguage(targetLocale);

    double speechRate = 0.4; // Base speed lowered
    switch (emotion) {
      case Emotion.sad:
        speechRate = 0.35;
        break;
      case Emotion.anxious:
        speechRate = 0.45;
        break;
      case Emotion.nostalgic:
        speechRate = 0.38;
        break;
      case Emotion.happy:
        speechRate = 0.48;
        break;
      default:
        speechRate = 0.4;
    }

    await _flutterTts.setSpeechRate(speechRate);

    _flutterTts.setCompletionHandler(() {
      if (onComplete != null) onComplete();
    });

    _flutterTts.setErrorHandler((msg) {
      if (onComplete != null) onComplete();
    });

    await _flutterTts.speak(text);
  }

  Future<void> speakInChunks(String fullResponse, {String language = "hi"}) async {
    final sentences = fullResponse.split(RegExp(r'(?<=[।.!?])\s+'));
    for (final sentence in sentences) {
      final trimmed = sentence.trim();
      if (trimmed.isEmpty) continue;
      await speakFast(trimmed, language: language);
    }
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  void destroy() {
    stop();
  }
}
