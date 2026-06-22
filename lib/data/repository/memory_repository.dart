import 'dart:typed_data';
import '../local/database.dart';
import 'local_embedding_engine.dart';

class MemoryRepository {
  final AppDatabase _db;
  final LocalEmbeddingEngine _embeddingEngine;

  MemoryRepository(this._db, this._embeddingEngine);

  Future<void> saveMemory(String content) async {
    final embeddingList = _embeddingEngine.embed(content);
    
    // Convert List<double> to Float32List then to Uint8List for blob storage
    final floatList = Float32List.fromList(embeddingList);
    final byteData = floatList.buffer.asUint8List();

    await _db.addMemory(MemoriesCompanion.insert(
      content: content,
      embedding: byteData,
    ));
  }

  Future<List<String>> retrieveRelevantMemories(String query, {int topK = 5}) async {
    final queryEmbedding = _embeddingEngine.embed(query);
    final allMemories = await _db.getAllMemories();

    final scoredMemories = allMemories.map((memory) {
      final floatList = Float32List.view(memory.embedding.buffer);
      final embedding = floatList.toList();
      final score = _embeddingEngine.cosineSimilarity(queryEmbedding, embedding);
      return MapEntry(memory.content, score);
    }).toList();

    scoredMemories.sort((a, b) => b.value.compareTo(a.value));
    
    return scoredMemories.take(topK).map((e) => e.key).toList();
  }
}
