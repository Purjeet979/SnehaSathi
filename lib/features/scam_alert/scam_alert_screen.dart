import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import 'scam_report_widget.dart';
import 'scam_awareness_feed.dart';

class ScamAlertScreen extends ConsumerStatefulWidget {
  const ScamAlertScreen({super.key});

  @override
  ConsumerState<ScamAlertScreen> createState() => _ScamAlertScreenState();
}

enum ScamVerdict { none, safe, caution, scam }

class _ScamAlertScreenState extends ConsumerState<ScamAlertScreen> {
  final TextEditingController _textController = TextEditingController();
  ScamVerdict _verdict = ScamVerdict.none;
  String _verdictMessage = '';
  bool _isChecking = false;

  final List<String> _scamKeywords = [
    'otp', 'kyc', 'account block', 'account suspend', 'upi pin', 
    'lottery', 'prize jeeta', 'turant', 'abhi', 'urgent'
  ];

  Future<void> _runCheck(String text) async {
    if (text.trim().isEmpty) return;
    
    setState(() {
      _isChecking = true;
      _verdict = ScamVerdict.none;
    });

    final lowerText = text.toLowerCase();
    
    // 1. Offline Check First
    bool isOfflineScam = false;
    for (final keyword in _scamKeywords) {
      if (lowerText.contains(keyword)) {
        isOfflineScam = true;
        break;
      }
    }

    // Default to Caution if offline yields nothing (because we haven't verified online yet)
    ScamVerdict currentVerdict = isOfflineScam ? ScamVerdict.scam : ScamVerdict.caution;
    String currentMessage = isOfflineScam 
        ? "Yeh dhokha lag raha hai" 
        : "Hum pakka nahi bata sakte, savdhan rahein";

    setState(() {
      _verdict = currentVerdict;
      _verdictMessage = currentMessage;
    });
    
    ref.read(ttsManagerProvider).speakFast(currentMessage, language: ref.read(languageProvider));

    // 2. Online LLM Check
    try {
      // ref.read(aiServiceProvider);
      // Simulate network delay for the LLM call
      await Future.delayed(const Duration(seconds: 2));
      
      // For now, simple mock: short texts are safe, long texts with keywords are caught above
      bool onlineIsSafe = text.length < 15 && !isOfflineScam;
      
      // Conflict Resolution: More cautious wins!
      // Red (Scam) > Amber (Caution) > Green (Safe)
      if (currentVerdict == ScamVerdict.scam) {
        // Red stays Red.
      } else if (!onlineIsSafe) {
        // Online caught a scam! Upgrade to Red.
        currentVerdict = ScamVerdict.scam;
        currentMessage = "Yeh dhokha lag raha hai";
      } else {
        // Online explicitly verified it as Safe. Upgrade to Green.
        currentVerdict = ScamVerdict.safe;
        currentMessage = "Yeh theek dikh raha hai";
      }
      
      setState(() {
        _verdict = currentVerdict;
        _verdictMessage = currentMessage;
      });
      
      ref.read(ttsManagerProvider).speakFast(currentMessage, language: ref.read(languageProvider));

    } catch (e) {
      // Network failed, we stay on the offline verdict (Amber or Red).
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saavdhan'),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ScamReportWidget(),
            const SizedBox(height: 24),
            Text('Message Ya Call Check Karein', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Yahan SMS paste karein ya mic dabayein...',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.mic, size: 36, color: Colors.blue),
                  onPressed: () {
                    ref.read(voiceInputProvider).startListening(
                      onStart: () {},
                      onStop: () {},
                      onResult: (text) {
                        _textController.text = text;
                      },
                      languageCode: ref.read(languageProvider) == 'hi' ? 'hi-IN' : 'en-IN'
                    );
                  },
                ),
              ),
              maxLines: 3,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isChecking ? null : () => _runCheck(_textController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700, 
                foregroundColor: Colors.white, 
                padding: const EdgeInsets.all(20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isChecking 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Yeh Sahi Hai?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 24),
            if (_verdict != ScamVerdict.none)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _verdict == ScamVerdict.scam 
                      ? Colors.red.shade100 
                      : (_verdict == ScamVerdict.safe ? Colors.green.shade100 : Colors.amber.shade100),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _verdict == ScamVerdict.scam 
                      ? Colors.red 
                      : (_verdict == ScamVerdict.safe ? Colors.green : Colors.amber),
                    width: 3,
                  )
                ),
                child: Column(
                  children: [
                    Icon(
                      _verdict == ScamVerdict.scam 
                          ? Icons.warning 
                          : (_verdict == ScamVerdict.safe ? Icons.check_circle : Icons.help_outline),
                      size: 72,
                      color: _verdict == ScamVerdict.scam 
                          ? Colors.red 
                          : (_verdict == ScamVerdict.safe ? Colors.green : Colors.amber.shade800),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _verdictMessage,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: _verdict == ScamVerdict.scam 
                          ? Colors.red.shade900 
                          : (_verdict == ScamVerdict.safe ? Colors.green.shade900 : Colors.amber.shade900),
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),
            const ScamAwarenessFeed(),
          ],
        ),
      ),
    );
  }
}
