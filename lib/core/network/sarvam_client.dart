import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:typed_data';

class SarvamApiException implements Exception {
  final String message;
  final int? statusCode;

  SarvamApiException(this.message, {this.statusCode});

  @override
  String toString() {
    final code = statusCode == null ? '' : ' ($statusCode)';
    return 'SarvamApiException$code: $message';
  }
}

class SarvamClient {
  static const String _baseUrl = 'https://api.sarvam.ai';
  static const String _apiKey = String.fromEnvironment('SARVAM_API_KEY', defaultValue: '##');

  final Dio _dio;

  SarvamClient() : _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'api-subscription-key': _apiKey,
      'Content-Type': 'application/json',
    },
  ));

  void _checkApiKey() {
    if (_apiKey.trim().isEmpty || _apiKey == '##') {
      throw SarvamApiException(
        'MISSING_API_KEY: Run with --dart-define=SARVAM_API_KEY=your_key',
      );
    }
  }

  SarvamApiException _mapDioError(Object error, String operation) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      final responseData = error.response?.data;
      final message = responseData == null
          ? error.message ?? '$operation failed'
          : responseData.toString();
      return SarvamApiException('$operation failed: $message', statusCode: statusCode);
    }
    return SarvamApiException('$operation failed: $error');
  }

  Future<String> chat(List<Map<String, String>> messages, {String languageCode = 'hi-IN', String dialect = 'Hindi'}) async {
    _checkApiKey();
    try {
      final response = await _dio.post(
        '/v1/chat/completions',
        data: {
          'model': 'sarvam-30b', // Restored to sarvam-30b as required by API
          'messages': messages,
          'max_tokens': 2000,
        },
      );

      final content = response.data['choices']?[0]?['message']?[ 'content'];
      if (content == null || content.toString().trim().isEmpty || content == 'null') {
        // Dialect-aware fallback
        if (languageCode == 'en') return "I am listening. Please tell me more.";
        if (dialect == 'Marathi') return "मी तुमचे बोलणे ऐकत आहे. कृपया मला अजून सांगा.";
        if (dialect == 'Gujarati') return "હું તમારી વાત સાંભળી રહ્યો છું. કૃપા કરીને મને વધુ કહો.";
        if (dialect == 'Punjabi') return "ਮੈਂ ਤੁਹਾਡੀ ਗੱਲ ਸੁਣ ਰਿਹਾ ਹਾਂ। ਕਿਰਪਾ ਕਰਕੇ ਮੈਨੂੰ ਹੋਰ ਦੱਸੋ।";
        if (dialect == 'Bihari') return "हम रउआ बात सुन तानी। कनि अउरी बताईं।";
        if (dialect == 'Haryanvi') return "मैं तेरी बात सुणूं सूं। थोड़ी और बता।";
        return "मैं आपकी बात सुन रही हूँ। कृपया और बताइये।";
      }
      return content.toString();
    } catch (e) {
      if (e is SarvamApiException) rethrow;
      throw _mapDioError(e, 'Sarvam chat');
    }
  }

  Future<Uint8List> textToSpeech(String text, {double pace = 1.2, String languageCode = 'hi-IN'}) async {
    _checkApiKey();
    if (text.trim().isEmpty) {
      throw SarvamApiException('TTS input cannot be empty');
    }
    try {
      // Sarvam TTS is called as a non-streaming endpoint here. UI callers should
      // chunk long text before invoking this method so audio can start sooner.
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
        throw SarvamApiException('Sarvam TTS returned empty audio');
      }
      
      return base64Decode(base64Audio);
    } catch (e) {
      if (e is SarvamApiException) rethrow;
      throw _mapDioError(e, 'Sarvam TTS');
    }
  }

  Future<String> translate(String text, String targetLang) async {
    _checkApiKey();
    if (text.trim().isEmpty) {
      throw SarvamApiException('Translate input cannot be empty');
    }
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
      throw _mapDioError(e, 'Sarvam translate');
    }
  }

  Future<String> speechToText(String filePath, {String languageCode = 'hi-IN'}) async {
    _checkApiKey();
    if (filePath.trim().isEmpty) {
      throw SarvamApiException('STT audio file path cannot be empty');
    }
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
      throw _mapDioError(e, 'Sarvam STT');
    }
  }
}
