import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConversationState {
  final List<String> recentEmotions;
  final bool shouldPivot;

  ConversationState({
    this.recentEmotions = const [],
    this.shouldPivot = false,
  });

  ConversationState copyWith({
    List<String>? recentEmotions,
    bool? shouldPivot,
  }) {
    return ConversationState(
      recentEmotions: recentEmotions ?? this.recentEmotions,
      shouldPivot: shouldPivot ?? this.shouldPivot,
    );
  }
}

class ConversationStateNotifier extends Notifier<ConversationState> {
  @override
  ConversationState build() {
    return ConversationState();
  }

  void addEmotion(String emotion) {
    final updatedEmotions = List<String>.from(state.recentEmotions)..add(emotion);
    if (updatedEmotions.length > 5) {
      updatedEmotions.removeAt(0); // Keep last 5
    }

    bool pivot = false;
    // Check if last two turns are sad or anxious
    if (updatedEmotions.length >= 2) {
      final last1 = updatedEmotions[updatedEmotions.length - 1];
      final last2 = updatedEmotions[updatedEmotions.length - 2];
      if ((last1 == 'sad' || last1 == 'anxious') && 
          (last2 == 'sad' || last2 == 'anxious')) {
        pivot = true;
      }
    }

    state = state.copyWith(
      recentEmotions: updatedEmotions,
      shouldPivot: pivot,
    );
  }

  void clearPivot() {
    state = state.copyWith(shouldPivot: false);
  }
}

final conversationStateProvider = NotifierProvider<ConversationStateNotifier, ConversationState>(
  ConversationStateNotifier.new,
);

// Mock onboarding data for life memories
final lifeMemoriesProvider = Provider<String>((ref) {
  return "shadi 1980 mein hui thi Kanpur mein, aur pehli naukri school teacher ki thi.";
});
