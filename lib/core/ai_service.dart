import 'network/sarvam_client.dart';
import 'tts/text_to_speech_manager.dart';

class AIService {
  final SarvamClient _sarvamClient;

  AIService(this._sarvamClient);

  Future<String> reply(String userText, {Emotion emotion = Emotion.neutral}) async {
    final messages = [
      {"role": "system", "content": "You are Sneh Saathi, a warm and caring AI companion for elderly Indian users. Speak kindly and clearly."},
      {"role": "user", "content": userText}
    ];
    
    final response = await _sarvamClient.chat(messages);
    return response;
  }
}
