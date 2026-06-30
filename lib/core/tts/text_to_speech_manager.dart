import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum Emotion { neutral, sad, anxious, nostalgic, happy }

class TextToSpeechManager {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isReady = false;
  Completer<void>? _activeCompleter;

  TextToSpeechManager() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("hi-IN");
    await _flutterTts.setSpeechRate(0.4); // Slower for Dadi
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.awaitSpeakCompletion(true); // Wait for speech to finish before returning
    _isReady = true;
    debugPrint('[TTS] Initialized and ready');
  }

  String _currentLang = "";
  double _currentRate = -1.0;

  Future<void> speakFast(String text, {String language = "hi", Emotion emotion = Emotion.neutral, Function? onComplete}) async {
    if (!_isReady) {
      debugPrint('[TTS] Not ready yet, skipping: ${text.substring(0, text.length.clamp(0, 30))}');
      return;
    }
    if (text.trim().isEmpty) {
      onComplete?.call();
      return;
    }

    final targetLocale = (language == "en") ? "en-IN" : "hi-IN";
    if (_currentLang != targetLocale) {
      await _flutterTts.setLanguage(targetLocale);
      _currentLang = targetLocale;
    }

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

    if (_currentRate != speechRate) {
      await _flutterTts.setSpeechRate(speechRate);
      _currentRate = speechRate;
    }

    // Cancel any previously pending completer
    _forceCompleteActive();

    final completer = Completer<void>();
    _activeCompleter = completer;

    _flutterTts.setCompletionHandler(() {
      debugPrint('[TTS] Completion handler fired');
      if (!completer.isCompleted) completer.complete();
      if (onComplete != null) onComplete();
    });

    _flutterTts.setErrorHandler((msg) {
      debugPrint('[TTS] Error handler fired: $msg');
      if (!completer.isCompleted) completer.complete();
      if (onComplete != null) onComplete();
    });

    _flutterTts.setCancelHandler(() {
      debugPrint('[TTS] Cancel handler fired');
      if (!completer.isCompleted) completer.complete();
    });

    debugPrint('[TTS] Speaking: ${text.substring(0, text.length.clamp(0, 40))}...');
    await _flutterTts.speak(text);

    // Timeout safety: if neither completion, error, nor cancel fires within
    // 10 seconds, force-complete to prevent indefinite hang on buggy devices.
    await completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint('[TTS] ⚠️ Timeout! Forcing completion after 10s');
        if (!completer.isCompleted) completer.complete();
      },
    );

    if (_activeCompleter == completer) {
      _activeCompleter = null;
    }
  }

  /// Force-complete any in-flight Completer so callers are never blocked.
  void _forceCompleteActive() {
    final c = _activeCompleter;
    if (c != null && !c.isCompleted) {
      debugPrint('[TTS] Force-completing previous active completer');
      c.complete();
    }
    _activeCompleter = null;
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
    debugPrint('[TTS] stop() called — force-completing active completer');
    // FIRST: force-complete any pending completer so the caller of speakFast
    // is unblocked immediately. This must happen BEFORE _flutterTts.stop()
    // because on some devices setCancelHandler never fires.
    _forceCompleteActive();
    await _flutterTts.stop();
  }

  void destroy() {
    _forceCompleteActive();
    _flutterTts.stop();
  }
}
