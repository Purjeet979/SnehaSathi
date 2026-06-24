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
    setState(() {
      _isChecking = true;
      _result = null;
    });

    try {
      final result = await ref.read(scamShieldProvider).scanInput(text);
      if (!mounted) return;
      setState(() => _result = result);
      await ref
          .read(ttsManagerProvider)
          .speakFast(result.hinglishExplanation, language: ref.read(languageProvider));
    } catch (e) {
      const fallback = ScamCheckResult(
        level: ScamResultLevel.amber,
        source: ScamResultSource.unknown,
        hinglishExplanation: 'Check complete nahi ho paya. Savdhan rahiye aur personal details share mat kijiye.',
        shouldAlertFamily: false,
      );
      if (mounted) {
        setState(() => _result = fallback);
        await ref
            .read(ttsManagerProvider)
            .speakFast(fallback.hinglishExplanation, language: ref.read(languageProvider));
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
