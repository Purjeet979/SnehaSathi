import 'network/sarvam_client.dart';
import 'tts/text_to_speech_manager.dart';

class AIService {
  final SarvamClient _sarvamClient;

  AIService(this._sarvamClient);

  Future<String> reply(String userText, {String languageCode = 'hi-IN'}) async {
    final systemPrompt = languageCode == 'hi-IN'
        ? "You are Sneh Saathi, a warm and caring AI companion for elderly Indians. You must respond in a mix of Hindi and English (Hinglish) using Devanagari script for Hindi words. Be extremely kind, patient, and caring."
        : "You are Sneh Saathi, a warm and caring AI companion for elderly Indians. You must respond strictly in clear, simple English. Be extremely kind, patient, and caring.";

    final messages = [
      {"role": "system", "content": systemPrompt},
      {"role": "user", "content": userText}
    ];
    
    final response = await _sarvamClient.chat(messages);
    return response;
  }
}
