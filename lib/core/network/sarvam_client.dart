import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:typed_data';

class SarvamClient {
  static const String _baseUrl = 'https://api.sarvam.ai';
  static const String _apiKey = 'YOUR_API_KEY_HERE'; // TODO: Retrieve from env/config

  final Dio _dio;

  SarvamClient() : _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'api-subscription-key': _apiKey,
      'Content-Type': 'application/json',
    },
  ));

  Future<String> chat(List<Map<String, String>> messages) async {
    try {
      final response = await _dio.post(
        '/v1/chat/completions',
        data: {
          'model': 'sarvam-30b',
          'messages': messages,
          'max_tokens': 300,
        },
      );

      final content = response.data['choices']?[0]?['message']?['content'];
      if (content == null || content.toString().isEmpty || content == 'null') {
        throw Exception('Sarvam API returned empty/null content');
      }
      return content.toString();
    } catch (e) {
      throw Exception('Sarvam API Error: $e');
    }
  }

  Future<Uint8List> textToSpeech(String text, {double pace = 1.2, String languageCode = 'hi-IN'}) async {
    try {
      final response = await _dio.post(
        '/text-to-speech',
        data: {
          'inputs': [text],
          'target_language_code': languageCode,
          'speaker': 'priya',
          'pace': pace,
          'model': 'bulbul:v3',
        },
      );

      final base64Audio = response.data['audios']?[0];
      if (base64Audio == null) {
        throw Exception('Sarvam TTS Error: Empty response audio');
      }
      
      return base64Decode(base64Audio);
    } catch (e) {
      throw Exception('Sarvam TTS Error: $e');
    }
  }

  Future<String> translate(String text, String targetLang) async {
    try {
      final response = await _dio.post(
        '/translate',
        data: {
          'input': text,
          'source_language_code': 'hi-IN',
          'target_language_code': targetLang,
          'model': 'mayura:v1',
        },
      );

      return response.data['translated_text'].toString();
    } catch (e) {
      throw Exception('Sarvam Translate Error: $e');
    }
  }

  Future<String> speechToText(String filePath, {String languageCode = 'hi-IN'}) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: 'audio_record.m4a'),
        'model': 'saaras:v3',
        'language_code': languageCode,
        'mode': 'codemix',
      });

      final response = await _dio.post(
        '/speech-to-text',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      return response.data['transcript'].toString();
    } catch (e) {
      throw Exception('Sarvam STT Error: $e');
    }
  }
}
