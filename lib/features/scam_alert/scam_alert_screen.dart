import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../scamshield/scam_shield_engine.dart';
import 'scam_report_widget.dart';
import 'scam_awareness_feed.dart';

class ScamAlertScreen extends ConsumerStatefulWidget {
  const ScamAlertScreen({super.key});

  @override
  ConsumerState<ScamAlertScreen> createState() => _ScamAlertScreenState();
}

class _ScamAlertScreenState extends ConsumerState<ScamAlertScreen> {
  final TextEditingController _textController = TextEditingController();
  ScamCheckResult? _result;
  bool _isChecking = false;

  Future<void> _runCheck(String text) async {
    if (text.trim().isEmpty) return;
    
    setState(() {
      _isChecking = true;
      _result = null;
    });

    final lang = ref.read(languageProvider);

    try {
      final result = await ref.read(scamShieldProvider).scanInput(text);
      if (!mounted) return;
      setState(() => _result = result);
      
      String explanation = result.hinglishExplanation;
      if (lang == 'en') {
        // Simple translation for now, but usually engine should return English
        explanation = explanation.replaceAll('Savdhan', 'Beware').replaceAll('Nahi', 'No');
      }

      await ref.read(ttsManagerProvider).speakFast(explanation, language: lang);
    } catch (e) {
      final fallbackMsg = lang == 'hi'
          ? 'Check complete nahi ho paya. Savdhan rahiye.'
          : 'Check could not be completed. Please stay safe.';
      
      const fallback = ScamCheckResult(
        level: ScamResultLevel.amber,
        source: ScamResultSource.unknown,
        hinglishExplanation: 'Error',
        shouldAlertFamily: false,
      );
      if (mounted) {
        setState(() => _result = fallback);
        await ref.read(ttsManagerProvider).speakFast(fallbackMsg, language: lang);
      }
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  Color _resultColor(ScamResultLevel level) {
    return switch (level) {
      ScamResultLevel.red => const Color(0xFFD32F2F),
      ScamResultLevel.amber => const Color(0xFFF57C00),
      ScamResultLevel.green => const Color(0xFF388E3C),
    };
  }

  IconData _resultIcon(ScamResultLevel level) {
    return switch (level) {
      ScamResultLevel.red => Icons.warning,
      ScamResultLevel.amber => Icons.help_outline,
      ScamResultLevel.green => Icons.check_circle,
    };
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        title: Text(lang == 'hi' ? 'Saavdhan' : 'Beware'),
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
            Text(
              lang == 'hi' ? 'Message Ya Call Check Karein' : 'Check Message or Call', 
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: lang == 'hi' ? 'Yahan SMS paste karein ya mic dabayein...' : 'Paste SMS here or use mic...',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.mic, size: 36, color: Colors.blue),
                  onPressed: () {
                    ref.read(voiceInputProvider).startListening(
                      onStart: () {},
                      onStop: () {},
                      onResult: (text) {
                        _textController.text = text;
                      },
                      languageCode: lang == 'hi' ? 'hi-IN' : 'en-IN'
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
                  : Text(
                      lang == 'hi' ? 'Yeh Sahi Hai?' : 'Is this safe?', 
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
                    ),
            ),
            const SizedBox(height: 24),
            if (_result != null)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _resultColor(_result!.level),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      _resultIcon(_result!.level),
                      size: 72,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _result!.hinglishExplanation,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
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
