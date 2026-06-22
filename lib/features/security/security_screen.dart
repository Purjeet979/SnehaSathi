import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';

class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  int _currentQuestionIndex = 0;
  
  final Map<String, List<String>> _questionsMap = {
    'hi': [
      "Darwaza band kiya?",
      "Khidki band hai?",
      "Gas off kiya?"
    ],
    'en': [
      "Did you lock the door?",
      "Is the window closed?",
      "Did you turn off the gas?"
    ]
  };

  final List<bool?> _answers = [null, null, null];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _askCurrentQuestion();
    });
  }

  void _askCurrentQuestion() {
    final lang = ref.read(languageProvider);
    final questions = _questionsMap[lang]!;
    if (_currentQuestionIndex < questions.length) {
      ref.read(ttsManagerProvider).speakFast(
        questions[_currentQuestionIndex], 
        language: lang
      );
    }
  }

  void _answerQuestion(bool isYes) {
    final lang = ref.read(languageProvider);
    final questions = _questionsMap[lang]!;
    
    setState(() {
      _answers[_currentQuestionIndex] = isYes;
      _currentQuestionIndex++;
    });

    if (_currentQuestionIndex < questions.length) {
      _askCurrentQuestion();
    } else {
      final allYes = _answers.every((a) => a == true);
      String msg;
      if (lang == 'hi') {
        msg = allYes 
            ? "Bahut badhiya dadi, ab chain se so jaiye. Goodnight!" 
            : "Kripya uth kar ek baar check kar lijiye. Safety zaroori hai!";
      } else {
        msg = allYes
            ? "Very good Dadi, now sleep peacefully. Goodnight!"
            : "Please get up and check once. Safety is important!";
      }
      ref.read(ttsManagerProvider).speakFast(msg, language: lang);
    }
  }

  void _listenForAnswer() {
    final lang = ref.read(languageProvider);
    final prompt = lang == 'hi' ? "Boliye, haan ya nahi?" : "Please say yes or no.";
    
    ref.read(ttsManagerProvider).speakFast(prompt, language: lang);
    ref.read(voiceInputProvider).startListening(
      onStart: () {},
      onStop: () {},
      onResult: (text) {
        final lower = text.toLowerCase();
        bool recognized = false;
        if (lang == 'hi') {
          if (lower.contains('haan') || lower.contains('yes') || lower.contains('ji')) {
            _answerQuestion(true);
            recognized = true;
          } else if (lower.contains('nahi') || lower.contains('no') || lower.contains('na')) {
            _answerQuestion(false);
            recognized = true;
          }
        } else {
          if (lower.contains('yes') || lower.contains('yeah') || lower.contains('yup')) {
            _answerQuestion(true);
            recognized = true;
          } else if (lower.contains('no') || lower.contains('not') || lower.contains('nope')) {
            _answerQuestion(false);
            recognized = true;
          }
        }

        if (!recognized) {
          final errorMsg = lang == 'hi' 
              ? "Samajh nahi aaya. Kripya button dabayein." 
              : "I didn't understand. Please press the button.";
          ref.read(ttsManagerProvider).speakFast(errorMsg, language: lang);
        }
      },
      languageCode: lang == 'hi' ? 'hi-IN' : 'en-IN'
    );
  }

  void _resetChecklist() {
    setState(() {
      _answers.fillRange(0, _answers.length, null);
      _currentQuestionIndex = 0;
    });
    _askCurrentQuestion();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final questions = _questionsMap[lang]!;
    final bool isDone = _currentQuestionIndex >= questions.length;

    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        title: Text(
          lang == 'hi' ? 'Raat Ki Safety Check' : 'Night Safety Check', 
          style: const TextStyle(fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: isDone ? _buildCompletionState(lang, questions) : _buildQuestionState(lang, questions),
        ),
      ),
    );
  }

  Widget _buildQuestionState(String lang, List<String> questions) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          lang == 'hi' 
              ? "Sawaal ${_currentQuestionIndex + 1} of ${questions.length}"
              : "Question ${_currentQuestionIndex + 1} of ${questions.length}",
          style: const TextStyle(fontSize: 20, color: Colors.grey, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
          ),
          child: Column(
            children: [
              const Icon(Icons.security, size: 80, color: Colors.orange),
              const SizedBox(height: 24),
              Text(
                questions[_currentQuestionIndex],
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _answerQuestion(true),
                icon: const Icon(Icons.check_circle, size: 40),
                label: Text(lang == 'hi' ? 'Haan' : 'Yes', style: const TextStyle(fontSize: 28)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _answerQuestion(false),
                icon: const Icon(Icons.cancel, size: 40),
                label: Text(lang == 'hi' ? 'Nahi' : 'No', style: const TextStyle(fontSize: 28)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: _listenForAnswer,
          icon: const Icon(Icons.mic, size: 40, color: Colors.blue),
          label: Text(
            lang == 'hi' ? 'Bolkar Jawab Dein' : 'Speak Your Answer', 
            style: const TextStyle(fontSize: 24, color: Colors.blue)
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade50,
            padding: const EdgeInsets.symmetric(vertical: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            side: BorderSide(color: Colors.blue.shade200, width: 2),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionState(String lang, List<String> questions) {
    final allYes = _answers.every((a) => a == true);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          allYes ? Icons.verified_user : Icons.warning_amber_rounded, 
          size: 120, 
          color: allYes ? Colors.green : Colors.red
        ),
        const SizedBox(height: 32),
        Text(
          allYes 
              ? (lang == 'hi' ? "Sab kuch safe hai!" : "Everything is safe!")
              : (lang == 'hi' ? "Kuch cheezein check karein!" : "Some things need checking!"),
          style: TextStyle(
            fontSize: 32, 
            fontWeight: FontWeight.bold, 
            color: allYes ? Colors.green.shade800 : Colors.red.shade800
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ...List.generate(questions.length, (index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_answers[index]! ? Icons.check : Icons.close, color: _answers[index]! ? Colors.green : Colors.red, size: 32),
              const SizedBox(width: 16),
              Text(questions[index], style: const TextStyle(fontSize: 24)),
            ],
          ),
        )),
        const SizedBox(height: 48),
        ElevatedButton.icon(
          onPressed: _resetChecklist,
          icon: const Icon(Icons.refresh, size: 32),
          label: Text(
            lang == 'hi' ? 'Wapas Check Karein' : 'Check Again', 
            style: const TextStyle(fontSize: 24)
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }
}
