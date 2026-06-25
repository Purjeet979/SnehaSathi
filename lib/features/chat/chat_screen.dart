import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/providers.dart';
import '../../data/local/database.dart';
import '../scamshield/scam_shield_engine.dart';
import 'providers/conversation_state.dart';

class Message {
  final String text;
  final bool isUser;
  Message(this.text, this.isUser);
}

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final List<Message> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isListening = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _startInitialGreeting();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startInitialGreeting() async {
    final lang = ref.read(languageProvider);
    final greeting = lang == 'hi' 
        ? "नमस्ते दादी जी! मैं आपका साथी हूँ। आज आप कैसे हैं?" 
        : "Namaste Dadi ji! I am your companion. How are you today?";
    
    setState(() {
      _messages.add(Message(greeting, false));
    });
    _scrollToBottom();
    
    final tts = ref.read(ttsManagerProvider);
    await tts.speakFast(greeting, language: lang);
  }

  void _toggleListening() async {
    final voiceHelper = ref.read(voiceInputProvider);
    final tts = ref.read(ttsManagerProvider);
    final lang = ref.read(languageProvider);

    await tts.stop();

    if (_isListening) {
      await voiceHelper.stopListening(
        () => setState(() => _isListening = false),
        _handleVoiceResult,
        lang == 'hi' ? 'hi-IN' : 'en-IN',
      );
    } else {
      await voiceHelper.startListening(
        onStart: () => setState(() => _isListening = true),
        onStop: () => setState(() => _isListening = false),
        onResult: _handleVoiceResult,
        languageCode: lang == 'hi' ? 'hi-IN' : 'en-IN',
      );
    }
  }

  void _handleVoiceResult(String userText) async {
    final tts = ref.read(ttsManagerProvider);
    final lang = ref.read(languageProvider);

    // Prevent STT failure messages from being processed as user input
    if (userText == "There is a slight issue. Could you please speak again?" || 
        userText == "Phir se boliye. Awaaz saaf nahi aayi.") {
      setState(() {
        _isListening = false;
        _isProcessing = false;
        _messages.add(Message(userText, false)); // Assistant message
      });
      _scrollToBottom();
      await tts.speakFast(userText, language: lang);
      return;
    }

    setState(() {
      _messages.add(Message(userText, true));
      _isProcessing = true;
    });
    _scrollToBottom();

    final aiService = ref.read(aiServiceProvider);
    final scamShield = ref.read(scamShieldProvider);
    final dialect = ref.read(dialectProvider);
    final db = ref.read(databaseProvider);

    db.addConversation(ConversationsCompanion(
      role: const drift.Value('user'),
      content: drift.Value(userText),
      timestamp: drift.Value(DateTime.now().millisecondsSinceEpoch),
    ));

    // 1. Real-time Scam Check
    final scamResult = await scamShield.scanInput(userText);
    if (scamResult.level == ScamResultLevel.red) {
      await tts.stop();
      await scamShield.triggerWarning();
      setState(() => _isProcessing = false);
      return;
    }

    // 2. Dawai Saathi - Smart Health Affirmations
    bool isMedPrompt = false;
    if (_messages.length >= 2) {
      final lastAiMessage = _messages[_messages.length - 2];
      if (!lastAiMessage.isUser) {
        final text = lastAiMessage.text.toLowerCase();
        if (text.contains("pill") || text.contains("dawai") || text.contains("medicine")) {
          isMedPrompt = true;
        }
      }
    }

    if (isMedPrompt) {
      final medState = await aiService.classifyMedicationResponse(userText);
      if (medState == 'deferred') {
        debugPrint("Dawai deferred: Scheduling local notification for 45 mins later");
        // Example: flutterLocalNotificationsPlugin.zonedSchedule(...)
      } else if (medState == 'refused') {
        debugPrint("Dawai refused: Quietly logging to family dashboard");
      }
    }

    // 3. Rooh Pehchaan - Emotion Classification
    aiService.classifyEmotion(userText).then((emotionData) {
      ref.read(conversationStateProvider.notifier).addEmotion(emotionData['emotion'] ?? 'neutral');
    });

    final convState = ref.read(conversationStateProvider);
    String? pivotInstruction;
    if (convState.shouldPivot) {
      pivotInstruction = "Dadi ne lagatar udaas ya anxious baat ki hai. Gently unke in life memories ke baare mein poochho: ${ref.read(lifeMemoriesProvider)}";
      ref.read(conversationStateProvider.notifier).clearPivot();
    }

    // 4. Normal Chat Flow
    try {
      final response = await aiService.reply(
        userText,
        languageCode: lang == 'hi' ? 'hi-IN' : 'en-IN',
        dialect: dialect,
        pivotInstruction: pivotInstruction,
      );
      setState(() {
        _messages.add(Message(response, false));
        _isProcessing = false;
      });
      _scrollToBottom();

      db.addConversation(ConversationsCompanion(
        role: const drift.Value('assistant'),
        content: drift.Value(response),
        timestamp: drift.Value(DateTime.now().millisecondsSinceEpoch),
      ));

      // Zero-Latency Voice Mode (Simulated via chunking)
      final sentences = response.split(RegExp(r'(?<=[।.!?])\s+'));
      for (final sentence in sentences) {
        if (sentence.trim().isNotEmpty) {
          await tts.speakFast(sentence, language: lang);
        }
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _messages.add(Message("माफ़ करना, मुझे समझने में थोड़ी दिक्कत हो रही है। ($e)", false));
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1), // Match home screen background
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D4037)),
                onPressed: () {
                  ref.read(ttsManagerProvider).stop();
                  Navigator.of(context).pop();
                },
                child: Text(
                  lang == 'hi' ? "वापस जाएँ" : "Go Back", 
                  style: const TextStyle(color: Colors.white)
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return Align(
                    alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: msg.isUser ? const Color(0xFFDCF8C6) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(msg.text, style: const TextStyle(fontSize: 18, color: Colors.black)),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (_isProcessing)
                    Text(
                      lang == 'hi' ? "सोच रहे हैं..." : "Thinking...", 
                      style: const TextStyle(color: Colors.grey, fontSize: 16)
                    ),
                  if (_isListening)
                    Text(
                      lang == 'hi' ? "सुन रहे हैं..." : "Listening...", 
                      style: const TextStyle(color: Colors.red, fontSize: 16)
                    ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _toggleListening,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: _isListening ? Colors.red : Colors.green,
                      child: const Icon(Icons.mic, color: Colors.white, size: 40),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
