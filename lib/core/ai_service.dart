import 'dart:convert';
import 'network/sarvam_client.dart';

class AIService {
  final SarvamClient _sarvamClient;

  AIService(this._sarvamClient);

  Future<String> reply(String userText, {String languageCode = 'hi-IN', String dialect = 'Hindi', String? pivotInstruction, String? elderName}) async {
    String dialectInstruction = "";
    if (languageCode == 'hi-IN') {
      if (dialect == 'Marathi') {
        dialectInstruction = " CRITICAL LANGUAGE RULE: The user selected Marathi dialect. You MUST write your ENTIRE response fluently in warm, natural Marathi language using Devanagari script (e.g. 'कसा काय', 'तुम्ही कसे आहात', 'काळजी करू नका', 'मी तुमच्या सोबत आहे'). Every sentence should be authentic Marathi.";
      } else if (dialect == 'Gujarati') {
        dialectInstruction = " CRITICAL LANGUAGE RULE: The user selected Gujarati dialect. You MUST write your ENTIRE response fluently in warm, natural Gujarati language (e.g. 'કેમ છો', 'તમે કેમ છો', 'ચિંતા ના કરો', 'હું તમારી સાથે છું'). Every sentence should be authentic Gujarati.";
      } else if (dialect == 'Punjabi') {
        dialectInstruction = " CRITICAL LANGUAGE RULE: The user selected Punjabi dialect. You MUST write your ENTIRE response fluently in warm, natural Punjabi language using Devanagari script (e.g. 'की हाल है', 'ਤੁਸੀਂ ਕਿਵੇਂ ਹੋ', 'ਚਿੰਤਾ ਨਾ ਕਰੋ', 'ਮੈਂ ਤੁਹਾਡੇ ਨਾਲ ਹਾਂ'). Every sentence should be authentic Punjabi.";
      } else if (dialect == 'Bihari') {
        dialectInstruction = " CRITICAL LANGUAGE RULE: The user selected Bihari/Bhojpuri dialect. You MUST write your ENTIRE response fluently in warm, natural Bihari/Bhojpuri dialect using Devanagari script (e.g. 'कैसन बानी', 'रउआ खातिर हम बानी', 'चिंता मत करीं'). Every sentence should be authentic Bihari.";
      } else if (dialect == 'Haryanvi') {
        dialectInstruction = " CRITICAL LANGUAGE RULE: The user selected Haryanvi dialect. You MUST write your ENTIRE response fluently in warm, natural Haryanvi dialect using Devanagari script (e.g. 'के हाल सै', 'घणी चिंता ना करै', 'मैं तेरे गेल्या सूं'). Every sentence should be authentic Haryanvi.";
      } else {
        dialectInstruction = " You MUST write your ENTIRE response in clear, gentle, respectful Hindi using Devanagari script (देवनागरी लिपि). Do NOT use Roman script for Hindi words.";
      }
    }

    final nameInstruction = (elderName != null && elderName.trim().isNotEmpty)
        ? " The user's name is ${elderName.trim()}. Address them respectfully using their name (e.g., ${elderName.trim()} जी / राव / भाऊ)."
        : "";

    final roohPehchaanInstruction = pivotInstruction != null 
        ? " ROOH PEHCHAAN PIVOT: $pivotInstruction Write this gently in the user's chosen language." 
        : " ROOH PEHCHAAN: Detect emotional state implicitly and respond naturally.";

    final basePrompt = languageCode == 'hi-IN'
        ? "You are Sneh Saathi, a warm and caring AI companion for elderly Indians. Speak with immense warmth, respect, patience, and love."
        : "You are Sneh Saathi, a warm and caring AI companion for elderly Indians. You must respond strictly in clear, simple English. Be extremely kind, patient, and caring.";

    final systemPrompt = "$basePrompt$nameInstruction$dialectInstruction$roohPehchaanInstruction";

    final messages = [
      {"role": "system", "content": systemPrompt},
      {"role": "user", "content": userText}
    ];
    
    final response = await _sarvamClient.chat(messages, languageCode: languageCode, dialect: dialect);
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
