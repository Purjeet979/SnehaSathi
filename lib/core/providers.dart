import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'network/sarvam_client.dart';
import '../data/repository/local_embedding_engine.dart';
import '../data/local/database.dart';
import '../data/repository/memory_repository.dart';
import 'tts/text_to_speech_manager.dart';
import 'ai_service.dart';
import 'stt/voice_input_helper.dart';
import '../features/scamshield/scam_shield_engine.dart';

final sarvamClientProvider = Provider<SarvamClient>((ref) {
  return SarvamClient();
});

final embeddingEngineProvider = Provider<LocalEmbeddingEngine>((ref) {
  return LocalEmbeddingEngine();
});

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final memoryRepositoryProvider = Provider<MemoryRepository>((ref) {
  return MemoryRepository(
    ref.watch(databaseProvider),
    ref.watch(embeddingEngineProvider),
  );
});

final ttsManagerProvider = Provider<TextToSpeechManager>((ref) {
  return TextToSpeechManager();
});

final aiServiceProvider = Provider<AIService>((ref) {
  return AIService(ref.watch(sarvamClientProvider));
});

final scamShieldProvider = Provider<ScamShieldEngine>((ref) {
  return ScamShieldEngine(
    ref.watch(ttsManagerProvider),
    ref.watch(sarvamClientProvider),
  );
});

final voiceInputProvider = Provider<VoiceInputHelper>((ref) {
  return VoiceInputHelper(ref.watch(sarvamClientProvider));
});

class LanguageNotifier extends Notifier<String> {
  @override
  String build() => 'hi';

  void setLanguage(String lang) {
    state = lang;
  }
}
final languageProvider = NotifierProvider<LanguageNotifier, String>(LanguageNotifier.new);

class DialectNotifier extends Notifier<String> {
  @override
  String build() => 'Hindi';

  void setDialect(String dialect) {
    state = dialect;
  }
}
final dialectProvider = NotifierProvider<DialectNotifier, String>(DialectNotifier.new);
