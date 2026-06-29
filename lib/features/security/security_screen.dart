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
  
  List<String> _getQuestions(String lang, String dialect) {
    if (lang == 'en') {
      return [
        "Did you lock the door?",
        "Is the window closed?",
        "Did you turn off the gas?"
      ];
    }
    if (dialect == 'Marathi') {
      return [
        "तुम्ही दार बंद केले का?",
        "खिडकी बंद आहे का?",
        "गॅस बंद केला का?"
      ];
    }
    return [
      "क्या आपने दरवाजा बंद किया?",
      "क्या खिड़की बंद है?",
      "क्या गैस बंद कर दिया?"
    ];
  }

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
    final dialect = ref.read(dialectProvider);
    final questions = _getQuestions(lang, dialect);
    if (_currentQuestionIndex < questions.length) {
      ref.read(ttsManagerProvider).speakFast(
        questions[_currentQuestionIndex], 
        language: lang
      );
    }
  }

  void _answerQuestion(bool isYes) {
    final lang = ref.read(languageProvider);
    final dialect = ref.read(dialectProvider);
    final questions = _getQuestions(lang, dialect);
    
    setState(() {
      _answers[_currentQuestionIndex] = isYes;
      _currentQuestionIndex++;
    });

    if (_currentQuestionIndex < questions.length) {
      _askCurrentQuestion();
    } else {
      final allYes = _answers.every((a) => a == true);
      String msg;
      if (lang == 'en') {
        msg = allYes
            ? "Very good! Now sleep peacefully. Goodnight!"
            : "Please get up and check once. Safety is important!";
      } else if (dialect == 'Marathi') {
        msg = allYes
            ? "खूप छान! आता शांतपणे झोपा. शुभ रात्री!"
            : "कृपया उठून एकदा तपासा. सुरक्षा महत्त्वाची आहे!";
      } else {
        msg = allYes 
            ? "बहुत बढ़िया! अब चैन से सो जाइये। शुभ रात्रि!" 
            : "कृपया उठ कर एक बार चेक कर लीजिये। सुरक्षा जरूरी है!";
      }
      ref.read(ttsManagerProvider).speakFast(msg, language: lang);
    }
  }

  void _listenForAnswer() {
    final lang = ref.read(languageProvider);
    final dialect = ref.read(dialectProvider);
    String prompt = "Please say yes or no.";
    if (lang != 'en') {
      prompt = dialect == 'Marathi' ? "बोला, होय की नाही?" : "बोलिये, हाँ या नहीं?";
    }
    
    ref.read(ttsManagerProvider).speakFast(prompt, language: lang);
    ref.read(voiceInputProvider).startListening(
      onStart: () {},
      onStop: () {},
      onResult: (text) {
        final lower = text.toLowerCase();
        bool recognized = false;
        if (lang == 'hi') {
          if (lower.contains('haan') || lower.contains('yes') || lower.contains('ji') || lower.contains('हाँ') || lower.contains('होय') || lower.contains('हो')) {
            _answerQuestion(true);
            recognized = true;
          } else if (lower.contains('nahi') || lower.contains('no') || lower.contains('na') || lower.contains('नहीं') || lower.contains('नाही')) {
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
          final errorMsg = lang == 'en'
              ? "I didn't understand. Please press the button."
              : (dialect == 'Marathi' ? "समजले नाही. कृपया बटण दाबा." : "समझ नहीं आया। कृपया बटन दबाएं।");
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
    final dialect = ref.watch(dialectProvider);
    final questions = _getQuestions(lang, dialect);
    final bool isDone = _currentQuestionIndex >= questions.length;

    String barTitle = lang == 'en' ? 'Night Safety Check' : (dialect == 'Marathi' ? 'रात्रीची सुरक्षा तपासणी' : 'रात की सुरक्षा जाँच');

    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        title: Text(
          barTitle, 
          style: const TextStyle(fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: isDone ? _buildCompletionState(lang, dialect, questions) : _buildQuestionState(lang, dialect, questions),
        ),
      ),
    );
  }

  Widget _buildQuestionState(String lang, String dialect, List<String> questions) {
    String qCount = lang == 'en' 
        ? "Question ${_currentQuestionIndex + 1} of ${questions.length}"
        : (dialect == 'Marathi' ? "प्रश्न ${_currentQuestionIndex + 1} / ${questions.length}" : "सवाल ${_currentQuestionIndex + 1} / ${questions.length}");
    String btnYes = lang == 'en' ? 'Yes' : (dialect == 'Marathi' ? 'होय' : 'हाँ');
    String btnNo = lang == 'en' ? 'No' : (dialect == 'Marathi' ? 'नाही' : 'नहीं');
    String btnVoice = lang == 'en' ? 'Answer via Voice' : (dialect == 'Marathi' ? 'बोलून उत्तर द्या' : 'बोलकर जवाब दें');

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          qCount,
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
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
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
                icon: const Icon(Icons.check_circle, size: 36),
                label: Text(btnYes, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _answerQuestion(false),
                icon: const Icon(Icons.cancel, size: 36),
                label: Text(btnNo, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: _listenForAnswer,
          icon: const Icon(Icons.mic, size: 32, color: Colors.blue),
          label: Text(btnVoice, style: const TextStyle(fontSize: 22, color: Colors.blue, fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 18),
            side: const BorderSide(color: Colors.blue, width: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionState(String lang, String dialect, List<String> questions) {
    final allYes = _answers.every((a) => a == true);

    String compTitle = lang == 'en' 
        ? (allYes ? "Everything is safe!" : "Some things need checking!")
        : (dialect == 'Marathi' 
            ? (allYes ? "सर्व काही सुरक्षित आहे!" : "काही गोष्टी तपासणे आवश्यक आहे!")
            : (allYes ? "सब कुछ सुरक्षित है!" : "कुछ चीजें चेक करें!"));

    String compBtn = lang == 'en' 
        ? 'Check Again' 
        : (dialect == 'Marathi' ? 'पुन्हा तपासा' : 'पुनः चेक करें');

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
          compTitle,
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
            compBtn, 
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
