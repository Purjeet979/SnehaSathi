import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final List<Map<String, String>> _historyCache = [];

  @override
  ConversationState build() {
    _loadPersistedEmotions();
    return ConversationState();
  }

  /// Load persisted emotion history into memory cache on startup
  Future<void> _loadPersistedEmotions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('emotion_history');
    if (raw != null && raw.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(raw);
        _historyCache.clear();
        _historyCache.addAll(
          decoded.map((e) => Map<String, String>.from(e as Map)),
        );
        final emotions = _historyCache
            .map((e) => e['emotion'] ?? 'neutral')
            .toList();
        // Keep only last 5 for the sliding window state
        final recent = emotions.length > 5 ? emotions.sublist(emotions.length - 5) : emotions;
        state = state.copyWith(recentEmotions: recent);
      } catch (_) {
        // Corrupted data — start fresh
      }
    }
  }

  /// Schedule a non-blocking background write to SharedPreferences without reading disk or stuttering UI thread
  void _scheduleBackgroundSave() {
    final snapshot = List<Map<String, String>>.from(_historyCache);
    Future.microtask(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('emotion_history', jsonEncode(snapshot));
      } catch (_) {}
    });
  }

  void addEmotion(String emotion) {
    // 1. Update sliding window state synchronously
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

    // 2. Synchronously update in-memory cache and cap at 20 items (no disk read needed!)
    _historyCache.add({
      'emotion': emotion,
      'timestamp': DateTime.now().toIso8601String(),
    });
    if (_historyCache.length > 20) {
      _historyCache.removeRange(0, _historyCache.length - 20);
    }

    // 3. Fire-and-forget background save without blocking conversation UI thread
    _scheduleBackgroundSave();
  }

  void clearPivot() {
    state = state.copyWith(shouldPivot: false);
  }
}

final conversationStateProvider = NotifierProvider<ConversationStateNotifier, ConversationState>(
  ConversationStateNotifier.new,
);

/// Life memories read from SharedPreferences (set during onboarding).
/// Falls back to empty string if not set, so Rooh Pehchaan pivot gracefully degrades.
final lifeMemoriesProvider = Provider<String>((ref) {
  return '';
});

/// Async version that reads from SharedPreferences
final lifeMemoriesFutureProvider = FutureProvider<String>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final milestones = prefs.getStringList('life_milestones') ?? [];
  if (milestones.isEmpty) return '';
  return milestones.join(', ');
});
