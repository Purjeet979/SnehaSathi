import 'dart:convert';
import 'package:flutter/services.dart';
import '../../core/network/sarvam_client.dart';
import '../../core/tts/text_to_speech_manager.dart';

enum ScamResultLevel { red, amber, green }
enum ScamResultSource { offlineKeyword, onlineAI, both, unknown }

class ScamCheckResult {
  final ScamResultLevel level;
  final ScamResultSource source;
  final String hinglishExplanation;
  final bool shouldAlertFamily;
  
  const ScamCheckResult({
    required this.level,
    required this.source,
    required this.hinglishExplanation,
    required this.shouldAlertFamily,
  });
}

class ScamShieldEngine {
  final TextToSpeechManager _ttsManager;
  final SarvamClient _sarvamClient;
  List<String> _highRiskKeywords = [];
  List<String> _mediumRiskKeywords = [];

  ScamShieldEngine(this._ttsManager, this._sarvamClient) {
    _loadKeywords();
  }

  Future<void> _loadKeywords() async {
    try {
      final jsonString = await rootBundle.loadString('assets/scam_keywords.json');
      final data = jsonDecode(jsonString);
      _highRiskKeywords = List<String>.from(data['high_risk'] ?? []);
      _mediumRiskKeywords = List<String>.from(data['medium_risk'] ?? []);
    } catch (e) {
      _highRiskKeywords = ['otp', 'kyc', 'account block', 'lottery', 'upi pin', 'cvv'];
      _mediumRiskKeywords = ['click here', 'verify karo', 'police case'];
    }
  }

  Future<ScamCheckResult> scanInput(String input) async {
    if (_highRiskKeywords.isEmpty && _mediumRiskKeywords.isEmpty) {
      await _loadKeywords();
    }
    final normalizedInput = _normalize(input);
    
    if (normalizedInput.trim().isEmpty) {
      return const ScamCheckResult(
        level: ScamResultLevel.amber,
        source: ScamResultSource.unknown,
        hinglishExplanation: 'Message khali hai. Kripya SMS ya call ka text daaliye.',
        shouldAlertFamily: false,
      );
    }

    final highRiskHit = _containsAny(normalizedInput, _highRiskKeywords);
    final mediumRiskHit = _containsAny(normalizedInput, _mediumRiskKeywords);
    final offlineLevel = highRiskHit
        ? ScamResultLevel.red
        : (mediumRiskHit ? ScamResultLevel.amber : ScamResultLevel.amber);

    final offlineResult = ScamCheckResult(
      level: offlineLevel,
      source: ScamResultSource.offlineKeyword,
      hinglishExplanation: highRiskHit
          ? 'Yeh message dhokha lag raha hai. OTP, PIN, CVV ya bank details share mat kijiye.'
          : 'Pakka nahi keh sakte. Online check ho raha hai, tab tak savdhan rahiye.',
      shouldAlertFamily: false,
    );

    ScamCheckResult onlineResult;
    try {
      onlineResult = await _runOnlineClassification(input);
    } catch (e) {
      return offlineResult.level == ScamResultLevel.red
          ? offlineResult
          : const ScamCheckResult(
              level: ScamResultLevel.amber,
              source: ScamResultSource.unknown,
              hinglishExplanation: 'Online check nahi ho paya. Is message par savdhan rahiye.',
              shouldAlertFamily: false,
            );
    }

    if (highRiskHit && onlineResult.level == ScamResultLevel.red) {
      return ScamCheckResult(
        level: ScamResultLevel.red,
        source: ScamResultSource.both,
        hinglishExplanation: onlineResult.hinglishExplanation,
        shouldAlertFamily: true,
      );
    }

    if (highRiskHit) {
      return ScamCheckResult(
        level: ScamResultLevel.red,
        source: ScamResultSource.offlineKeyword,
        hinglishExplanation: offlineResult.hinglishExplanation,
        shouldAlertFamily: false,
      );
    }

    return onlineResult;
  }

  Future<void> triggerWarning() async {
    final warningText = "Dadi, savdhaan rahein! Ye ek fraud ho sakta hai. Apna OTP, password, ya bank details kisi ko na dein.";
    await _ttsManager.speakFast(warningText, emotion: Emotion.anxious);
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('आधार', 'aadhar')
        .replaceAll('ओटीपी', 'otp')
        .replaceAll('पिन', 'pin')
        .replaceAll('केवाईसी', 'kyc');
  }

  bool _containsAny(String input, List<String> keywords) {
    return keywords.any((keyword) => input.contains(_normalize(keyword)));
  }

  Future<ScamCheckResult> _runOnlineClassification(String input) async {
    final response = await _sarvamClient.chat([
      {
        'role': 'system',
        'content': '''
You classify Indian scam messages. Return ONLY JSON:
{"level":"red|amber|green","hinglishExplanation":"short user-safe explanation"}
Rules:
- red: asks for OTP, PIN, CVV, payment, urgent account action, lottery/prize, arrest/police threat, suspicious link.
- amber: ambiguous, promotional, unclear, or insufficient context.
- green: only if clearly legitimate and no sensitive action requested.
Never include markdown.
''',
      },
      {'role': 'user', 'content': input},
    ]);

    try {
      final decoded = jsonDecode(response.replaceAll('```json', '').replaceAll('```', '').trim());
      final levelText = decoded['level']?.toString().toLowerCase();
      final explanation = decoded['hinglishExplanation']?.toString().trim();
      if (explanation == null || explanation.isEmpty) {
        return _unexpectedOnlineFormat();
      }
      return switch (levelText) {
        'red' => ScamCheckResult(
            level: ScamResultLevel.red,
            source: ScamResultSource.onlineAI,
            hinglishExplanation: explanation,
            shouldAlertFamily: false,
          ),
        'green' => ScamCheckResult(
            level: ScamResultLevel.green,
            source: ScamResultSource.onlineAI,
            hinglishExplanation: explanation,
            shouldAlertFamily: false,
          ),
        'amber' => ScamCheckResult(
            level: ScamResultLevel.amber,
            source: ScamResultSource.onlineAI,
            hinglishExplanation: explanation,
            shouldAlertFamily: false,
          ),
        _ => _unexpectedOnlineFormat(),
      };
    } catch (e) {
      return _unexpectedOnlineFormat();
    }
  }

  ScamCheckResult _unexpectedOnlineFormat() {
    return const ScamCheckResult(
      level: ScamResultLevel.amber,
      source: ScamResultSource.unknown,
      hinglishExplanation: 'Online jawab samajh nahi aaya. Savdhan rahiye aur personal details share mat kijiye.',
      shouldAlertFamily: false,
    );
  }
}
