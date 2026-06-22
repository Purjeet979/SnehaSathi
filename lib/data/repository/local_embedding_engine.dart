import 'dart:math';

class LocalEmbeddingEngine {
  /// Dummy embed function that returns a 384-dimensional zero vector, 
  /// matching the placeholder from the native Android codebase.
  List<double> embed(String text) {
    return List<double>.filled(384, 0.0);
  }

  double cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0.0;
    
    double dot = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    
    return dot / (sqrt(normA) * sqrt(normB) + 1e-8);
  }
}
