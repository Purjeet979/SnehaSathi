import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/notifications/security_notification_manager.dart';
import '../core/providers.dart';

class ApiTestScreen extends ConsumerStatefulWidget {
  const ApiTestScreen({super.key});

  @override
  ConsumerState<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends ConsumerState<ApiTestScreen> {
  final List<String> _logs = [];
  bool _isRunning = false;

  void _addLog(String message) {
    setState(() {
      _logs.insert(0, '${DateTime.now().toIso8601String()}  $message');
    });
  }

  Future<void> _run(String label, Future<String> Function() action) async {
    setState(() => _isRunning = true);
    _addLog('START $label');
    try {
      final result = await action().timeout(const Duration(seconds: 45));
      _addLog('OK $label\n$result');
    } catch (e) {
      _addLog('ERROR $label\n$e');
    } finally {
      if (mounted) {
        setState(() => _isRunning = false);
      }
    }
  }

  Future<String> _testSarvamChat() async {
    final response = await ref.read(sarvamClientProvider).chat([
      {
        'role': 'system',
        'content': 'Reply in one short Hinglish sentence.',
      },
      {
        'role': 'user',
        'content': 'Namaste, API test chal raha hai.',
      },
    ]);
    return response;
  }

  Future<String> _testSarvamTts() async {
    final audio = await ref.read(sarvamClientProvider).textToSpeech(
      'Namaste Dadi, yeh Sarvam TTS ka chhota test hai. Aapki awaaz saaf sunai deni chahiye.',
    );
    return 'Received ${audio.length} audio bytes';
  }

  Future<String> _testScamClassification() async {
    final samples = [
      'Aapka bank account block ho gaya hai. OTP bhejiye warna account band ho jayega.',
      'Rs 500 debited from your account at ATM. If not you, call official bank number.',
      'Congratulations lottery prize jeeta hai. Refund ke liye UPI PIN bhejo.',
      'Aaj mall mein discount offer hai, link pe jao.',
      '',
    ];

    final results = <Map<String, String>>[];
    final engine = ref.read(scamShieldProvider);
    for (final sample in samples) {
      final result = await engine.scanInput(sample);
      results.add({
        'input': sample,
        'level': result.level.name,
        'source': result.source.name,
        'explanation': result.hinglishExplanation,
      });
    }
    return const JsonEncoder.withIndent('  ').convert(results);
  }

  Future<String> _testSttOnce() async {
    ref.read(voiceInputProvider).startListening(
      onStart: () => _addLog('STT recording started'),
      onStop: () => _addLog('STT recording stopped'),
      onResult: (text) => _addLog('STT result: $text'),
      languageCode: 'hi-IN',
    );
    return 'Recording started. Speak once and pause for auto-stop.';
  }

  Future<String> _testLocalNotification() async {
    await SecurityNotificationManager.scheduleOneShotTestNotification();
    return 'Scheduled local notification for about 10 seconds from now.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _isRunning ? null : () => _run('Sarvam chat', _testSarvamChat),
                  child: const Text('Sarvam Chat'),
                ),
                ElevatedButton(
                  onPressed: _isRunning ? null : () => _run('Sarvam TTS', _testSarvamTts),
                  child: const Text('Sarvam TTS'),
                ),
                ElevatedButton(
                  onPressed: _isRunning ? null : () => _run('Scam classification', _testScamClassification),
                  child: const Text('Scam AI'),
                ),
                ElevatedButton(
                  onPressed: _isRunning ? null : () => _run('Sarvam STT', _testSttOnce),
                  child: const Text('Sarvam STT'),
                ),
                ElevatedButton(
                  onPressed: _isRunning ? null : () => _run('Local notification', _testLocalNotification),
                  child: const Text('Notification'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _logs.length,
                  itemBuilder: (context, index) => SelectableText(
                    _logs[index],
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
