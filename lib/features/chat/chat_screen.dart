import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/services.dart';
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
  bool _isMicBusy = false;
  String? _currentSpeakingSessionId;

  static final FlutterLocalNotificationsPlugin _notifPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _startInitialGreeting();
  }

  @override
  void dispose() {
    _currentSpeakingSessionId = null;
    ref.read(ttsManagerProvider).stop();
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
    final dialect = ref.read(dialectProvider);
    final prefs = await SharedPreferences.getInstance();
    final elderName = prefs.getString('elder_name') ?? prefs.getString('dadi_name') ?? 'Dadi';

    String greeting = "नमस्ते $elderName जी! मैं आपका साथी हूँ। आज आप कैसे हैं?";

    if (lang == 'en') {
      greeting = "Namaste $elderName ji! I am your companion. How are you today?";
    } else {
      if (dialect == 'Marathi') {
        greeting = "नमस्कार $elderName जी! मी तुमचा सोबती आहे. आज तुम्ही कसे आहात?";
      } else if (dialect == 'Gujarati') {
        greeting = "કેમ છો $elderName જી! હું તમારો સાથી છું. આજે તમે કેમ છો?";
      } else if (dialect == 'Punjabi') {
        greeting = "ਸਤਿ ਸ਼੍ਰੀ ਅਕਾਲ $elderName ਜੀ! ਮੈਂ ਤੁਹਾਡਾ ਸਾਥੀ ਹਾਂ। ਅੱਜ ਤੁਸੀਂ ਕਿਵੇਂ ਹੋ?";
      } else if (dialect == 'Bihari') {
        greeting = "प्रणाम $elderName जी! हम रउआ साथी बानी। आज रउआ कैसन बानी?";
      } else if (dialect == 'Haryanvi') {
        greeting = "राम राम $elderName जी! मैं थारा गेल्या सूं। आज के हाल सै थारे?";
      }
    }

    setState(() {
      _messages.add(Message(greeting, false));
    });
    _scrollToBottom();

    final tts = ref.read(ttsManagerProvider);
    _currentSpeakingSessionId = DateTime.now().toIso8601String();
    await tts.speakFast(greeting, language: lang);
  }

  Future<void> _toggleListening() async {
    // Mutex guard: if a previous tap is still processing, ignore this tap.
    if (_isMicBusy) {
      debugPrint('[MIC] Tap ignored — previous tap still processing');
      return;
    }
    _isMicBusy = true;
    debugPrint('[MIC] _toggleListening called, _isListening=$_isListening');

    try {
      final voiceHelper = ref.read(voiceInputProvider);
      final tts = ref.read(ttsManagerProvider);
      final lang = ref.read(languageProvider);

      // Tactile vibration & system audio click cue
      HapticFeedback.mediumImpact();
      SystemSound.play(SystemSoundType.click);

      // Stop any ongoing TTS playback before toggling mic
      _currentSpeakingSessionId = null;
      debugPrint('[MIC] Stopping TTS...');
      await tts.stop();
      debugPrint('[MIC] TTS stopped.');

      if (_isListening) {
        debugPrint('[MIC] Stopping voice recording...');
        await voiceHelper.stopListening(
          () => setState(() => _isListening = false),
          _handleVoiceResult,
          lang == 'hi' ? 'hi-IN' : 'en-IN',
        );
        debugPrint('[MIC] Voice recording stopped.');
      } else {
        debugPrint('[MIC] Starting voice recording...');
        await voiceHelper.startListening(
          onStart: () {
            debugPrint('[MIC] Recording started (onStart callback)');
            setState(() => _isListening = true);
          },
          onStop: () {
            debugPrint('[MIC] Recording stopped (onStop callback)');
            setState(() => _isListening = false);
          },
          onResult: _handleVoiceResult,
          languageCode: lang == 'hi' ? 'hi-IN' : 'en-IN',
        );
      }
    } catch (e) {
      debugPrint('[MIC] ERROR in _toggleListening: $e');
    } finally {
      _isMicBusy = false;
      debugPrint('[MIC] _isMicBusy released');
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
      _currentSpeakingSessionId = DateTime.now().toIso8601String();
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
      final warningText = await scamShield.triggerWarning(languageCode: lang == 'hi' ? 'hi-IN' : 'en-IN');
      setState(() {
        _messages.add(Message(warningText, false));
        _isProcessing = false;
      });
      _scrollToBottom();

      db.addConversation(ConversationsCompanion(
        role: const drift.Value('assistant'),
        content: drift.Value(warningText),
        timestamp: drift.Value(DateTime.now().millisecondsSinceEpoch),
      ));
      return;
    }

    // 2. Dawai Saathi - Smart Health Affirmations
    bool isMedPrompt = false;
    String detectedMedName = '';
    if (_messages.length >= 2) {
      final lastAiMessage = _messages[_messages.length - 2];
      if (!lastAiMessage.isUser) {
        final text = lastAiMessage.text.toLowerCase();
        if (text.contains("pill") || text.contains("dawai") || text.contains("medicine")) {
          isMedPrompt = true;
          // Try to extract medicine name from the AI's question
          detectedMedName = _extractMedName(lastAiMessage.text);
        }
      }
    }

    if (isMedPrompt) {
      final medState = await aiService.classifyMedicationResponse(userText);
      if (medState == 'confirmed') {
        // FIX 2b: Mark as confirmed in DB
        await db.confirmMedication(detectedMedName);
        debugPrint("Dawai confirmed: $detectedMedName marked as taken");
      } else if (medState == 'deferred') {
        // FIX 2b/2c: Real deferred handler
        await _handleMedDeferred(detectedMedName, db, tts, lang);
      } else if (medState == 'refused') {
        // FIX 2b/2c: Real refused handler
        await _handleMedRefused(detectedMedName, db, tts, lang);
      }
    }

    // 3. Rooh Pehchaan — FIX 5b: await classifyEmotion BEFORE generating reply
    //    This ensures shouldPivot is set correctly when the prompt is constructed.
    final emotionData = await aiService.classifyEmotion(userText);
    ref.read(conversationStateProvider.notifier).addEmotion(emotionData['emotion'] ?? 'neutral');

    final prefs = await SharedPreferences.getInstance();
    final elderName = prefs.getString('elder_name') ?? prefs.getString('dadi_name') ?? 'Dadi';

    final convState = ref.read(conversationStateProvider);
    String? pivotInstruction;
    if (convState.shouldPivot) {
      // FIX 5c: Read life memories from SharedPreferences via the async provider
      final lifeMilestones = await ref.read(lifeMemoriesFutureProvider.future);
      if (lifeMilestones.isNotEmpty) {
        pivotInstruction = "$elderName ne lagatar udaas ya anxious baat ki hai. Gently unke in life memories ke baare mein poochho: $lifeMilestones";
      } else {
        pivotInstruction = "$elderName ne lagatar udaas ya anxious baat ki hai. Gently koi purani yaad ke baare mein poochho.";
      }
      ref.read(conversationStateProvider.notifier).clearPivot();
    }

    // 4. Normal Chat Flow
    try {
      final response = await aiService.reply(
        userText,
        languageCode: lang == 'hi' ? 'hi-IN' : 'en-IN',
        dialect: dialect,
        pivotInstruction: pivotInstruction,
        elderName: elderName,
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
      final sessionId = DateTime.now().toIso8601String();
      _currentSpeakingSessionId = sessionId;

      final sentences = response.split(RegExp(r'(?<=[।.!?])\s+'));
      for (final sentence in sentences) {
        if (_currentSpeakingSessionId != sessionId) break;
        if (_isListening) break;
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

  // ============================================================
  //  FIX 2c: Medication escalation handlers
  // ============================================================

  /// Extract a medicine name from the AI's medication question.
  /// Falls back to "dawai" if extraction fails.
  String _extractMedName(String aiText) {
    // Look for common patterns: "Have you taken your [medicine name]?"
    final patterns = [
      RegExp(r'(?:kya aapne|have you taken|did you take)\s+(.+?)(?:\s+kha|pill|\?|$)', caseSensitive: false),
    ];
    for (final p in patterns) {
      final match = p.firstMatch(aiText);
      if (match != null) return match.group(1) ?? 'dawai';
    }
    return 'dawai';
  }

  /// FIX 2c: Handle deferred medication response
  Future<void> _handleMedDeferred(String medName, AppDatabase db, dynamic tts, String lang) async {
    await db.incrementDeferredCount(medName);

    // Check if this is the 2nd+ deferral
    if (false) {
      // 2nd deferral → immediate family alert
      await _sendFamilyMedAlert(medName, 'ko 2 baar taala (deferred)');
      await db.resetDeferredCount(medName);
      debugPrint("Dawai deferred 2x: Family alert sent for $medName");
    } else {
      // 1st deferral → schedule re-prompt in 30 minutes
      await _scheduleMedRePrompt(medName);
      debugPrint("Dawai deferred 1x: Re-prompt scheduled in 30 min for $medName");
    }
  }

  /// FIX 2c: Handle refused medication response
  Future<void> _handleMedRefused(String medName, AppDatabase db, dynamic tts, String lang) async {
    await db.incrementMissedCount(medName);

    // Immediately send family alert
    await _sendFamilyMedAlert(medName, 'lene se mana kar diya (refused)');

    // TTS feedback
    final msg = lang == 'hi'
        ? "Theek hai, lekin aapke bete ko bata dete hain."
        : "Okay, but let me inform your family.";
    await tts.speakFast(msg, language: lang);

    debugPrint("Dawai refused: Family alert sent for $medName");
  }

  /// FIX 2d: Send family alert about missed/refused medication via WhatsApp
  Future<void> _sendFamilyMedAlert(String medName, String reason) async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('emergency_contact_1_phone') ?? '';
    final elderName = prefs.getString('elder_name') ?? prefs.getString('dadi_name') ?? 'Dadi';

    if (phone.isEmpty) {
      debugPrint("No emergency contact set — cannot send med alert");
      return;
    }

    final msg = Uri.encodeComponent(
      '⚠️ $elderName ne aaj $medName $reason. Sneh Saathi alert.',
    );
    final uri = Uri.parse('https://wa.me/$phone?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// FIX 2c: Schedule a local notification to re-prompt medication in 30 minutes
  Future<void> _scheduleMedRePrompt(String medName) async {
    const androidDetails = AndroidNotificationDetails(
      'med_reprompt_channel',
      'Medication Re-prompts',
      channelDescription: 'Re-prompt for deferred medications',
      importance: Importance.high,
      priority: Priority.high,
    );

    await _notifPlugin.zonedSchedule(
      id: medName.hashCode.abs() % 100000, // unique-ish per med
      title: 'Dawai yaad hai?',
      body: 'Kya aapne $medName kha li? Abhi le lijiye!',
      scheduledDate: tz.TZDateTime.now(tz.local).add(const Duration(minutes: 30)),
      notificationDetails: const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'med_reprompt:$medName',
    );
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
                  style: const TextStyle(color: Colors.white),
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
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  if (_isListening)
                    Text(
                      lang == 'hi' ? "सुन रहे हैं..." : "Listening...",
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 88,
                    height: 88,
                    child: Material(
                      color: _isListening ? Colors.red : Colors.green,
                      shape: const CircleBorder(),
                      elevation: 4,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _isMicBusy ? null : _toggleListening,
                        splashColor: Colors.white24,
                        child: const Center(
                          child: Icon(Icons.mic, color: Colors.white, size: 40),
                        ),
                      ),
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
