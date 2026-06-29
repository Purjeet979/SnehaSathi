import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/providers.dart';
import '../../core/tts/text_to_speech_manager.dart';
import '../../data/local/database.dart';
import '../../data/local/user_preferences_repository.dart';
import '../../core/workers/work_manager_helper.dart';
import '../home/home_screen.dart';

/// Caregiver Setup Screen — first-launch onboarding.
///
/// Path A: "Main iske liye set kar raha/rahi hoon" — full keyboard form
/// Path B: "Main khud karunga/karungi" — voice-guided wizard (TTS + STT)
class CaregiverSetupScreen extends ConsumerStatefulWidget {
  const CaregiverSetupScreen({super.key});

  @override
  ConsumerState<CaregiverSetupScreen> createState() => _CaregiverSetupScreenState();
}

class _CaregiverSetupScreenState extends ConsumerState<CaregiverSetupScreen> {
  // --- Path selector ---
  bool? _isCaregiverPath; // null = not chosen yet

  // --- Form data (shared between Path A and Path B) ---
  final _nameCtrl = TextEditingController(text: '');
  String _dialect = 'Hindi';
  String _summaryFrequency = 'Daily';
  final List<_EmergencyContact> _contacts = [
    _EmergencyContact(),
    _EmergencyContact(),
    _EmergencyContact(),
  ];
  final List<_MedEntry> _medications = [_MedEntry()];
  final List<TextEditingController> _milestoneCtrs = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  // --- Voice wizard state (Path B) ---
  int _voiceStep = 0; // 0-based
  bool _isListening = false;
  bool _voiceConfirmPending = false;
  String _voiceLastHeard = '';

  // --- Completion ---
  bool _setupComplete = false;

  static const _dialects = ['Hindi', 'Marathi', 'Gujarati', 'Punjabi', 'Bihari', 'Haryanvi'];
  static const _timeSlots = ['Subah', 'Dopahar', 'Shaam', 'Raat'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    for (final c in _contacts) {
      c.nameCtrl.dispose();
      c.phoneCtrl.dispose();
    }
    for (final m in _medications) {
      m.nameCtrl.dispose();
    }
    for (final c in _milestoneCtrs) {
      c.dispose();
    }
    super.dispose();
  }

  // ============================================================
  //  SAVE LOGIC (shared by both paths)
  // ============================================================

  Future<void> _saveAndFinish() async {
    // Phone number validation constraints
    final primaryPhone = _contacts[0].phoneCtrl.text.trim();
    if (_isCaregiverPath == true && primaryPhone.isNotEmpty && primaryPhone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kripya sahi 10-digit mobile number bharein (Please enter a valid 10-digit phone number)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    for (final c in _contacts) {
      final p = c.phoneCtrl.text.trim();
      if (p.isNotEmpty && p.length < 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Contact "${c.nameCtrl.text.trim().isEmpty ? "Emergency" : c.nameCtrl.text.trim()}" ka phone number sahi nahi hai (Must be 10 digits)'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final db = ref.read(databaseProvider);

    // Elder name
    final elderName = _nameCtrl.text.trim().isEmpty ? 'Dadi' : _nameCtrl.text.trim();
    await prefs.setString('elder_name', elderName);
    await prefs.setString('dadi_name', elderName); // legacy key

    // Dialect
    await prefs.setString('selected_dialect', _dialect);

    // Summary frequency (Daily digest vs Weekly)
    await prefs.setString('summary_frequency', _summaryFrequency);
    await WorkManagerHelper.scheduleGhostwriterWorker();

    // Emergency contacts (up to 3)
    for (int i = 0; i < _contacts.length; i++) {
      final c = _contacts[i];
      if (c.phoneCtrl.text.trim().isNotEmpty) {
        await prefs.setString('emergency_contact_${i + 1}_name', c.nameCtrl.text.trim());
        await prefs.setString('emergency_contact_${i + 1}_phone', c.phoneCtrl.text.trim());
      }
    }
    // Also write first contact to legacy key
    if (_contacts[0].phoneCtrl.text.trim().isNotEmpty) {
      await prefs.setString('emergency_contact', _contacts[0].phoneCtrl.text.trim());
    }

    // Medications → Drift DB
    for (final m in _medications) {
      if (m.nameCtrl.text.trim().isNotEmpty) {
        await db.addMedication(MedicationsCompanion.insert(
          name: m.nameCtrl.text.trim(),
          timeToTake: m.time,
        ));
      }
    }

    // Life milestones → SharedPreferences (List<String>)
    final milestones = _milestoneCtrs
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    await prefs.setStringList('life_milestones', milestones);

    // Prompt for battery optimization exemption to prevent aggressive OEM background killing (MIUI, ColorOS, Samsung)
    try {
      if (await Permission.ignoreBatteryOptimizations.isDenied) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    } catch (_) {}

    // Mark onboarding done
    await prefs.setBool('onboarding_complete', true);

    // Update Riverpod providers
    ref.read(dialectProvider.notifier).setDialect(_dialect);

    setState(() => _setupComplete = true);
  }

  void _goToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _shareSetupSummary() async {
    final elderName = _nameCtrl.text.trim().isEmpty ? 'Dadi' : _nameCtrl.text.trim();
    final contactNames = _contacts
        .where((c) => c.nameCtrl.text.trim().isNotEmpty)
        .map((c) => c.nameCtrl.text.trim())
        .join(', ');
    final medNames = _medications
        .where((m) => m.nameCtrl.text.trim().isNotEmpty)
        .map((m) => m.nameCtrl.text.trim())
        .join(', ');

    final summary = '''
Sneh Saathi setup complete ✅
Naam: $elderName
Bhasha: $_dialect
Emergency contacts: ${contactNames.isEmpty ? 'Not set' : contactNames}
Dawaiyan: ${medNames.isEmpty ? 'Not set' : medNames}
''';

    final encoded = Uri.encodeComponent(summary.trim());
    final uri = Uri.parse('whatsapp://send?text=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ============================================================
  //  PATH B — VOICE WIZARD
  // ============================================================

  final List<Map<String, String>> _voicePrompts = [
    {
      'hi': 'Aapka naam kya hai? Boliye.',
      'en': 'What is your name? Please speak.',
    },
    {
      'hi': 'Apne bete ya beti ka phone number bataiye.',
      'en': 'Please tell me your son or daughter\'s phone number.',
    },
    {
      'hi': 'Aap kaunsi dawai lete hain? Dawai ka naam boliye.',
      'en': 'What medicine do you take? Please say the name.',
    },
  ];

  void _startVoiceWizard() {
    setState(() {
      _voiceStep = 0;
      _isCaregiverPath = false;
    });
    _speakCurrentStep();
  }

  void _speakCurrentStep() {
    if (_voiceStep >= _voicePrompts.length) return;
    final tts = ref.read(ttsManagerProvider);
    final lang = ref.read(languageProvider);
    final prompt = _voicePrompts[_voiceStep][lang == 'en' ? 'en' : 'hi']!;
    tts.speakFast(prompt, language: lang);
  }

  void _listenForVoiceAnswer() {
    final voiceHelper = ref.read(voiceInputProvider);
    final lang = ref.read(languageProvider);

    setState(() => _isListening = true);

    voiceHelper.startListening(
      onStart: () {},
      onStop: () => setState(() => _isListening = false),
      onResult: (text) {
        if (text.contains('issue') || text.contains('Phir se boliye')) {
          // STT failure — retry
          setState(() => _isListening = false);
          final tts = ref.read(ttsManagerProvider);
          tts.speakFast(
            lang == 'en' ? 'I didn\'t catch that. Let me ask again.' : 'Samajh nahi aaya. Phir se poochta hoon.',
            language: lang,
          );
          Future.delayed(const Duration(seconds: 2), _speakCurrentStep);
          return;
        }

        setState(() {
          _voiceLastHeard = text;
          _voiceConfirmPending = true;
          _isListening = false;
        });

        // Confirm back to user
        final tts = ref.read(ttsManagerProvider);
        final confirmMsg = lang == 'en'
            ? 'I heard: $text. Is this correct?'
            : 'Maine suna: $text. Kya yeh sahi hai?';
        tts.speakFast(confirmMsg, language: lang);
      },
      languageCode: lang == 'hi' ? 'hi-IN' : 'en-IN',
    );
  }

  void _confirmVoiceAnswer(bool accepted) {
    if (!accepted) {
      setState(() => _voiceConfirmPending = false);
      _speakCurrentStep();
      return;
    }

    // Apply the answer
    switch (_voiceStep) {
      case 0: // Name
        _nameCtrl.text = _voiceLastHeard;
        break;
      case 1: // Phone
        // Extract digits from spoken text
        final digits = _voiceLastHeard.replaceAll(RegExp(r'[^0-9]'), '');
        _contacts[0].phoneCtrl.text = digits;
        _contacts[0].nameCtrl.text = 'Family';
        break;
      case 2: // Medication
        _medications[0].nameCtrl.text = _voiceLastHeard;
        break;
    }

    setState(() {
      _voiceConfirmPending = false;
      _voiceStep++;
    });

    if (_voiceStep < _voicePrompts.length) {
      Future.delayed(const Duration(milliseconds: 500), _speakCurrentStep);
    } else {
      // All voice steps done — save
      _saveAndFinish();
    }
  }

  // ============================================================
  //  BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (_setupComplete) {
      return _buildCompletionScreen();
    }
    if (_isCaregiverPath == null) {
      return _buildPathSelector();
    }
    if (_isCaregiverPath == false) {
      return _buildVoiceWizard();
    }
    return _buildCaregiverForm();
  }

  // --- Path selector ---
  Widget _buildPathSelector() {
    final selectedLang = ref.watch(languageProvider);
    final isHindi = selectedLang == 'hi';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              // Language Toggle at top right
              Align(
                alignment: Alignment.topRight,
                child: ToggleButtons(
                  isSelected: [selectedLang == 'hi', selectedLang == 'en'],
                  onPressed: (index) {
                    ref.read(languageProvider.notifier).setLanguage(index == 0 ? 'hi' : 'en');
                  },
                  borderRadius: BorderRadius.circular(12),
                  constraints: const BoxConstraints(minHeight: 32.0, minWidth: 44.0),
                  fillColor: Colors.red.shade100,
                  selectedColor: Colors.red.shade900,
                  children: const [
                    Text('हिंदी', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('EN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Issue 1: App Logo
                    Image.asset(
                      'assets/images/sneh_saathi_logo.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.favorite, color: Colors.red.shade700, size: 80),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sneh Saathi',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Colors.red.shade900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isHindi ? 'आपका प्यारा साथी' : 'Your Loving Companion',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.brown.shade400,
                      ),
                    ),
                    const SizedBox(height: 36),
                    Text(
                      isHindi ? 'Pehle, yeh app kisne setup karna hai?' : 'Who is setting up this app first?',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    // Path A — Caregiver
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => setState(() => _isCaregiverPath = true),
                        icon: const Icon(Icons.person_add, size: 32),
                        label: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isHindi ? 'Main iske liye set kar raha/rahi hoon' : 'I am setting this up for my parent',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                isHindi ? '(Beta/Beti/Caregiver)' : '(Son/Daughter/Caregiver)',
                                style: const TextStyle(fontSize: 13, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          alignment: Alignment.centerLeft,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Path B — Elder self
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _startVoiceWizard,
                        icon: const Icon(Icons.mic, size: 32),
                        label: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isHindi ? 'Main khud karunga/karungi' : 'I will set it up myself',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                isHindi ? '(Bolkar setup karein)' : '(Voice guided setup)',
                                style: const TextStyle(fontSize: 13, color: Colors.black45),
                              ),
                            ],
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red.shade900,
                          alignment: Alignment.centerLeft,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.red.shade200, width: 2),
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
      ),
    );
  }

  // --- Path A: Caregiver Form ---
  Widget _buildCaregiverForm() {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        title: const Text('Setup for your parent', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _isCaregiverPath = null),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          // --- Elder Name ---
          _sectionLabel('Elder\'s Name'),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              hintText: 'e.g. Dadi, Nani, Amma, Papa',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 24),

          // --- Dialect ---
          _sectionLabel('Regional Dialect'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButton<String>(
              value: _dialect,
              isExpanded: true,
              underline: const SizedBox(),
              style: const TextStyle(fontSize: 20, color: Colors.black87),
              items: _dialects.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _dialect = val);
              },
            ),
          ),
          const SizedBox(height: 24),

          // --- Family Summary Frequency ---
          _sectionLabel('Family Update Frequency'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButton<String>(
              value: _summaryFrequency,
              isExpanded: true,
              underline: const SizedBox(),
              style: const TextStyle(fontSize: 20, color: Colors.black87),
              items: const [
                DropdownMenuItem(value: 'Daily', child: Text('Daily Digest (Rozana - Recommended)')),
                DropdownMenuItem(value: 'Weekly', child: Text('Weekly Summary (Har Hafte)')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _summaryFrequency = val);
              },
            ),
          ),
          const SizedBox(height: 24),

          // --- Emergency Contacts ---
          _sectionLabel('Emergency Contacts'),
          ...List.generate(_contacts.length, (i) => _buildContactField(i)),
          const SizedBox(height: 24),

          // --- Medications ---
          _sectionLabel('Medications'),
          ...List.generate(_medications.length, (i) => _buildMedField(i)),
          TextButton.icon(
            onPressed: () => setState(() => _medications.add(_MedEntry())),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Add more medicine', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 24),

          // --- Life Milestones ---
          _sectionLabel('Life Milestones (for Rooh Pehchaan)'),
          const Text(
            'These memories help the AI comfort your parent with familiar stories when they feel sad.',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          ...List.generate(_milestoneCtrs.length, (i) {
            final hints = [
              'e.g. Wedding year and city — Shadi 1980 Kanpur',
              'e.g. Kids\' names — Rohan, Priya',
              'e.g. Hometown or favorite memory — Gaon Bareilly mein bachpan',
            ];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: _milestoneCtrs[i],
                decoration: InputDecoration(
                  hintText: hints[i],
                  hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                style: const TextStyle(fontSize: 18),
              ),
            );
          }),
          const SizedBox(height: 32),

          // --- Submit ---
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveAndFinish,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Setup Complete ✅', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildContactField(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: _contacts[index].nameCtrl,
              decoration: InputDecoration(
                hintText: 'Name (e.g. ${['Beta', 'Beti', 'Padosi'][index]})',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              style: const TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextField(
              controller: _contacts[index].phoneCtrl,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: '10-digit number',
                counterText: "",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedField(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _medications[index].nameCtrl,
              decoration: InputDecoration(
                hintText: 'Medicine name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              style: const TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButton<String>(
                value: _medications[index].time,
                isExpanded: true,
                underline: const SizedBox(),
                items: _timeSlots.map((t) {
                  final labels = {'Subah': 'Morning', 'Dopahar': 'Afternoon', 'Shaam': 'Evening', 'Raat': 'Night'};
                  return DropdownMenuItem(value: t, child: Text(labels[t]!));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _medications[index].time = val);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown.shade700)),
    );
  }

  // --- Path B: Voice Wizard ---
  Widget _buildVoiceWizard() {
    final stepLabels = ['Name', 'Emergency Contact', 'Medicine'];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        title: Text(
          'Step ${_voiceStep + 1} of ${_voicePrompts.length}: ${stepLabels[_voiceStep.clamp(0, stepLabels.length - 1)]}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _isCaregiverPath = null),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Progress
              LinearProgressIndicator(
                value: (_voiceStep + 1) / _voicePrompts.length,
                backgroundColor: Colors.red.shade100,
                valueColor: AlwaysStoppedAnimation(Colors.red.shade700),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 40),

              // Question display
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    Icon(
                      _voiceStep == 0 ? Icons.person : _voiceStep == 1 ? Icons.phone : Icons.medical_services,
                      size: 60,
                      color: Colors.red.shade700,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _voicePrompts[_voiceStep.clamp(0, _voicePrompts.length - 1)]['hi']!,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    if (_voiceLastHeard.isNotEmpty && _voiceConfirmPending) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Text(
                          'Suna: "$_voiceLastHeard"',
                          style: TextStyle(fontSize: 22, color: Colors.green.shade900),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Buttons
              if (_voiceConfirmPending) ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmVoiceAnswer(true),
                        icon: const Icon(Icons.check, size: 32),
                        label: const Text('Haan, sahi hai', style: TextStyle(fontSize: 20)),
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
                        onPressed: () => _confirmVoiceAnswer(false),
                        icon: const Icon(Icons.refresh, size: 32),
                        label: const Text('Phir se bolein', style: TextStyle(fontSize: 20)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                GestureDetector(
                  onTap: _listenForVoiceAnswer,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: _isListening ? Colors.red : Colors.red.shade700,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.shade200.withAlpha(150),
                          blurRadius: _isListening ? 30 : 15,
                          spreadRadius: _isListening ? 10 : 3,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.hearing : Icons.mic,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isListening ? 'Sun raha hoon...' : 'Bolne ke liye tap karein',
                  style: TextStyle(
                    fontSize: 18,
                    color: _isListening ? Colors.red : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --- Completion Screen ---
  Widget _buildCompletionScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600, size: 100),
                const SizedBox(height: 24),
                Text(
                  'Setup ho gayi! ✅',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Colors.green.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Ab ${_nameCtrl.text.trim().isEmpty ? "Dadi" : _nameCtrl.text.trim()} Sneh Saathi use kar sakte hain.',
                  style: const TextStyle(fontSize: 20, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _shareSetupSummary,
                    icon: const Icon(Icons.share, size: 28),
                    label: const Text('Parivar ko share karein',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _goToHome,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Shuru karein →',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Helper classes ---
class _EmergencyContact {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
}

class _MedEntry {
  final nameCtrl = TextEditingController();
  String time = 'Subah';
}
