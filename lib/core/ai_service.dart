import 'dart:convert';
import 'network/sarvam_client.dart';

class AIService {
  final SarvamClient _sarvamClient;

  AIService(this._sarvamClient);

  Future<String> reply(String userText, {String languageCode = 'hi-IN', String dialect = 'Hindi', String? pivotInstruction}) async {
    String dialectInstruction = "";
    if (languageCode == 'hi-IN') {
      if (dialect == 'Marathi') {
        dialectInstruction = " IMPORTANT: You must start your response with a Marathi filler word like 'Bhau' or 'Kasa kay'.";
      } else if (dialect == 'Gujarati') {
        dialectInstruction = " IMPORTANT: You must start your response with a Gujarati filler word like 'Kem cho', 'Dikra', or 'Mota bhai'.";
      } else if (dialect == 'Punjabi') {
        dialectInstruction = " IMPORTANT: You must start your response with a Punjabi filler word like 'Puttar', 'Ki haal hai', or 'Oye'.";
      } else if (dialect == 'Bihari') {
        dialectInstruction = " IMPORTANT: You must start your response with a Bihari filler word like 'Babu', 'Kaisan ba', or 'Bhaiya'.";
      } else if (dialect == 'Haryanvi') {
        dialectInstruction = " IMPORTANT: You must start your response with a Haryanvi filler word like 'Tau', 'Ke haal se', or 'Chhore'.";
      }
    }

    final roohPehchaanInstruction = pivotInstruction != null 
        ? " ROOH PEHCHAAN PIVOT: $pivotInstruction" 
        : " ROOH PEHCHAAN: Detect the user's emotional state implicitly and respond naturally.";

    final basePrompt = languageCode == 'hi-IN'
        ? "You are Sneh Saathi, a warm and caring AI companion for elderly Indians. You must respond in a mix of Hindi and English (Hinglish) using Devanagari script for Hindi words. Be extremely kind, patient, and caring."
        : "You are Sneh Saathi, a warm and caring AI companion for elderly Indians. You must respond strictly in clear, simple English. Be extremely kind, patient, and caring.";

    final systemPrompt = "$basePrompt$dialectInstruction$roohPehchaanInstruction";

    final messages = [
      {"role": "system", "content": systemPrompt},
      {"role": "user", "content": userText}
    ];
    
    final response = await _sarvamClient.chat(messages);
    return response;
  }

  Future<Map<String, dynamic>> classifyEmotion(String userText) async {
    final systemPrompt = '''
You are a silent emotion classifier. Analyze the user's text and return ONLY a valid JSON object.
Fields required:
- "emotion": must be one of "sad", "anxious", "happy", "neutral"
- "nostalgia_trigger": boolean, true if the user mentions old memories, past days, etc.
Example: {"emotion": "sad", "nostalgia_trigger": false}
''';
    final messages = [
      {"role": "system", "content": systemPrompt},
      {"role": "user", "content": userText}
    ];
    try {
      final response = await _sarvamClient.chat(messages);
      final jsonStr = response.replaceAll('```json', '').replaceAll('```', '').trim();
      return jsonDecode(jsonStr);
    } catch (e) {
      return {"emotion": "neutral", "nostalgia_trigger": false};
    }
  }

  Future<String> classifyMedicationResponse(String userText) async {
    final systemPrompt = '''
You are a silent classifier for medication affirmations. Analyze the user's response to "Have you taken your medicine?"
Return EXACTLY one of these words:
- confirmed (if they said yes, taken, haan, le li, done)
- deferred (if they said baad mein, thodi der mein, later)
- refused (if they said no, nahi, nahi lunga)
If unsure, return deferred.
''';
    final messages = [
      {"role": "system", "content": systemPrompt},
      {"role": "user", "content": userText}
    ];
    try {
      final response = await _sarvamClient.chat(messages);
      final text = response.toLowerCase().trim();
      if (text.contains('confirmed')) return 'confirmed';
      if (text.contains('refused')) return 'refused';
      return 'deferred';
    } catch (e) {
      return 'deferred';
    }
  }
}
