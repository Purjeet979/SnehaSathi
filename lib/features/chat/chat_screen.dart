import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';

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
  bool _isListening = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _startInitialGreeting();
  }

  void _startInitialGreeting() async {
    final lang = ref.read(languageProvider);
    final greeting = lang == 'hi' 
        ? "नमस्ते दादी जी! मैं आपका साथी हूँ। आज आप कैसे हैं?" 
        : "Namaste Dadi ji! I am your companion. How are you today?";
    
    setState(() {
      _messages.add(Message(greeting, false));
    });
    
    final tts = ref.read(ttsManagerProvider);
    await tts.speakFast(greeting, language: lang);
  }

  void _toggleListening() async {
    final voiceHelper = ref.read(voiceInputProvider);
    final tts = ref.read(ttsManagerProvider);
    final lang = ref.read(languageProvider);

    await tts.stop();

    if (_isListening) {
      // Logic to stop manually if needed
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
    setState(() {
      _messages.add(Message(userText, true));
      _isProcessing = true;
    });

    final aiService = ref.read(aiServiceProvider);
    final tts = ref.read(ttsManagerProvider);
    final scamShield = ref.read(scamShieldProvider);
    final lang = ref.read(languageProvider);

    // 1. Real-time Scam Check
    if (scamShield.scanInput(userText)) {
      await tts.stop();
      await scamShield.triggerWarning();
      setState(() => _isProcessing = false);
      // Even after scam warning, restart listening if it's supposed to be continuous
      Future.delayed(const Duration(seconds: 3), () => _toggleListening());
      return;
    }

    // 2. Normal Chat Flow
    try {
      final response = await aiService.reply(userText);
      setState(() {
        _messages.add(Message(response, false));
        _isProcessing = false;
      });
      await tts.speakFast(response, language: lang, onComplete: () {
        // Automatically start listening again after bot finishes speaking
        if (mounted) {
          _toggleListening();
        }
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      // Restart listening even on error so they don't have to click
      if (mounted) {
        _toggleListening();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
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
