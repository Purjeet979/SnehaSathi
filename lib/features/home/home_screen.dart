import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/providers.dart';
import '../../core/platform/native_sms_sender.dart';
import '../../data/local/user_preferences_repository.dart';
import 'dart:math' as math;
import '../chat/chat_screen.dart';
import '../medication/meds_screen.dart';
import '../family/family_screen.dart';
import '../security/security_screen.dart';
import '../scam_alert/scam_alert_screen.dart';
import '../onboarding/caregiver_setup_screen.dart';
import '../../core/workers/work_manager_helper.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _mantraController;

  @override
  void initState() {
    super.initState();
    _mantraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _mantraController.dispose();
    super.dispose();
  }

  void _showSettingsDialog(BuildContext context, WidgetRef ref) {
    final userPrefs = ref.read(userPreferencesProvider);
    final nameCtrl = TextEditingController(text: userPrefs.dadiName);
    final phoneCtrl = TextEditingController(text: userPrefs.emergencyContact);
    bool cloudSyncEnabled = true;
    String summaryFrequency = 'Daily';

    showDialog(
      context: context,
      builder: (ctx) {
        return FutureBuilder<SharedPreferences>(
          future: SharedPreferences.getInstance(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              cloudSyncEnabled = snapshot.data!.getBool('cloud_sync_enabled') ?? true;
              summaryFrequency = snapshot.data!.getString('summary_frequency') ?? 'Daily';
            }
            return StatefulBuilder(
              builder: (ctx, setDialogState) => AlertDialog(
                title: const Text('Aapki Details & Privacy'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Aapka Naam (e.g. Dadi, Dada, ya apna naam)'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneCtrl,
                        decoration: const InputDecoration(labelText: 'Family Emergency Number'),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: summaryFrequency,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Auto-Summary Frequency', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'Daily', child: Text('Daily Digest (Rozana)')),
                          DropdownMenuItem(value: 'Weekly', child: Text('Weekly Summary (Har Hafte)')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              summaryFrequency = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Parivar Summary Share karein', style: TextStyle(fontSize: 15)),
                        subtitle: const Text('Summary WhatsApp / Cloud par save karein', style: TextStyle(fontSize: 12)),
                        value: cloudSyncEnabled,
                        onChanged: (val) {
                          setDialogState(() {
                            cloudSyncEnabled = val;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final sp = await SharedPreferences.getInstance();
                            await sp.setBool('onboarding_complete', false);
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) => const CaregiverSetupScreen()),
                              );
                            }
                          },
                          icon: const Icon(Icons.restart_alt, color: Colors.deepOrange),
                          label: const Text('Setup Wizard Phir Se Chalayein', style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.deepOrange),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                  ElevatedButton(
                    onPressed: () async {
                      await userPrefs.setDadiName(nameCtrl.text);
                      await userPrefs.setEmergencyContact(phoneCtrl.text);
                      // Also write to onboarding keys for consistency
                      final sp = await SharedPreferences.getInstance();
                      await sp.setString('elder_name', nameCtrl.text);
                      await sp.setString('emergency_contact_1_phone', phoneCtrl.text);
                      await sp.setBool('cloud_sync_enabled', cloudSyncEnabled);
                      await sp.setString('summary_frequency', summaryFrequency);
                      await WorkManagerHelper.scheduleGhostwriterWorker();
                      if (ctx.mounted) Navigator.pop(ctx);
                      setState(() {});
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedLang = ref.watch(languageProvider);
    final selectedDialect = ref.watch(dialectProvider);
    final userPrefs = ref.watch(userPreferencesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1), // Warm cream background
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8E1), // Matches screen background
        elevation: 0, // Removed elevation for a seamless look
        toolbarHeight: 100,
        titleSpacing: 8,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/sneh_saathi_logo.png',
              width: 72,
              height: 72,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.favorite, color: Colors.red.shade700, size: 54),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Sneh Saathi',
                    style: TextStyle(
                      color: Colors.red.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    selectedLang == 'hi' ? 'आपका प्यारा साथी' : 'Your Caring Companion',
                    style: TextStyle(
                      color: Colors.brown.shade400,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.brown, size: 24),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  onPressed: () => _showSettingsDialog(context, ref),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.language, color: Colors.red.shade900, size: 18),
                      const SizedBox(width: 4),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: () {
                            if (selectedLang == 'en') return 'English';
                            if (['Hindi', 'Marathi', 'Gujarati', 'Punjabi', 'Bihari', 'Haryanvi'].contains(selectedDialect)) {
                              return selectedDialect;
                            }
                            return 'Hindi';
                          }(),
                          isDense: true,
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.brown, size: 20),
                          style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.bold, fontSize: 13),
                          items: const [
                            DropdownMenuItem(value: 'English', child: Text('English')),
                            DropdownMenuItem(value: 'Hindi', child: Text('हिंदी')),
                            DropdownMenuItem(value: 'Marathi', child: Text('मराठी')),
                            DropdownMenuItem(value: 'Gujarati', child: Text('ગુજરાતી')),
                            DropdownMenuItem(value: 'Punjabi', child: Text('ਪੰਜਾਬੀ')),
                            DropdownMenuItem(value: 'Bihari', child: Text('बिहारी')),
                            DropdownMenuItem(value: 'Haryanvi', child: Text('हरियाणवी')),
                          ],
                          onChanged: (newValue) {
                            if (newValue != null) {
                              if (newValue == 'English') {
                                ref.read(languageProvider.notifier).setLanguage('en');
                              } else {
                                ref.read(languageProvider.notifier).setLanguage('hi');
                                ref.read(dialectProvider.notifier).setDialect(newValue);
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Animated Mantra Background
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _mantraController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: MantraPainter(_mantraController.value),
                  );
                },
              ),
            ),
          ),
          // Content Overlay
          SafeArea(
            child: Column(
              children: [
                ...() {
                  String welcomeGreeting = selectedLang == 'hi' ? 'नमस्ते, ${userPrefs.dadiName}!' : 'Namaste, ${userPrefs.dadiName}!';
                  String welcomeSubtitle = selectedLang == 'hi' ? 'आज मैं आपकी क्या मदद कर सकता हूँ?' : 'How can I help you today?';

                  if (selectedLang == 'hi') {
                    if (selectedDialect == 'Marathi') {
                      welcomeGreeting = 'नमस्कार, ${userPrefs.dadiName}!';
                      welcomeSubtitle = 'आज मी तुम्हाला कशी मदत करू शकतो?';
                    } else if (selectedDialect == 'Gujarati') {
                      welcomeGreeting = 'કેમ છો, ${userPrefs.dadiName}!';
                      welcomeSubtitle = 'આજે હું તમારી શું મદદ કરી શકું?';
                    } else if (selectedDialect == 'Punjabi') {
                      welcomeGreeting = 'ਸਤਿ ਸ਼੍ਰੀ ਅਕਾਲ, ${userPrefs.dadiName}!';
                      welcomeSubtitle = 'ਅੱਜ ਮੈਂ ਤੁਹਾਡੀ ਕੀ ਮਦਦ ਕਰ ਸਕਦਾ ਹਾਂ?';
                    } else if (selectedDialect == 'Bihari') {
                      welcomeGreeting = 'प्रणाम, ${userPrefs.dadiName}!';
                      welcomeSubtitle = 'आज हम रउआ का मदद करीं?';
                    } else if (selectedDialect == 'Haryanvi') {
                      welcomeGreeting = 'राम राम, ${userPrefs.dadiName}!';
                      welcomeSubtitle = 'आज मैं थारी के मदद कर सकूं?';
                    }
                  }

                  return [
                    const SizedBox(height: 30),
                    Text(
                      welcomeGreeting,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        backgroundColor: Colors.white.withValues(alpha: 0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      welcomeSubtitle,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        backgroundColor: Colors.white.withValues(alpha: 0.5),
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ];
                }(),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double centerRadius = 80;
                      final double outerRadius = 140; // Fixed radius for stability
                      final Offset center = Offset(
                        constraints.maxWidth / 2,
                        constraints.maxHeight / 2 - 20,
                      );

                      return Stack(
                        children: [
                          // SOS Button (Center)
                          Positioned(
                            left: center.dx - centerRadius,
                            top: center.dy - centerRadius,
                            child: _buildSosButton(centerRadius * 2),
                          ),
                          // Radial Buttons
                          ..._buildRadialButtons(center, outerRadius, context, ref),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSosButton(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.red.shade700,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.red.shade300.withAlpha(128),
            blurRadius: 20,
            spreadRadius: 5,
          )
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.vibrate();
          _triggerSOS(context, ref);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emergency, color: Colors.white, size: 40),
            SizedBox(height: 4),
            Text(
              'SOS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// FIX 3b/3c: Full SOS implementation with countdown, GPS, phone call, silent SMS
  Future<void> _triggerSOS(BuildContext context, WidgetRef ref) async {
    final tts = ref.read(ttsManagerProvider);
    final lang = ref.read(languageProvider);

    // Show countdown dialog
    bool cancelled = false;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SosCountdownDialog(
        onCancel: () {
          cancelled = true;
          Navigator.of(ctx).pop(false);
        },
      ),
    );

    if (cancelled || result == false) return;

    // Request permissions
    await [Permission.phone, Permission.sms, Permission.location].request();

    // Get GPS location
    String locationUrl = '';
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      locationUrl = 'https://maps.google.com/?q=${position.latitude},${position.longitude}';
    } catch (e) {
      locationUrl = '(Location unavailable)';
    }

    // Read emergency contacts from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final elderName = prefs.getString('elder_name') ?? prefs.getString('dadi_name') ?? 'Dadi';
    final List<String> emergencyPhones = [];
    for (int i = 1; i <= 3; i++) {
      final phone = prefs.getString('emergency_contact_${i}_phone');
      if (phone != null && phone.isNotEmpty) {
        emergencyPhones.add(phone);
      }
    }
    // Fallback: check legacy key
    if (emergencyPhones.isEmpty) {
      final legacy = prefs.getString('emergency_contact');
      if (legacy != null && legacy.isNotEmpty) {
        emergencyPhones.add(legacy);
      }
    }

    final smsBody = 'SOS: $elderName ko madad chahiye! Location: $locationUrl — Sneh Saathi';

    // Step 1: Call first emergency contact (most reliable)
    if (emergencyPhones.isNotEmpty) {
      final callUri = Uri.parse('tel:${emergencyPhones[0]}');
      if (await canLaunchUrl(callUri)) {
        await launchUrl(callUri);
      }
    }

    // Step 2: Send silent SMS to ALL contacts with location (via native SmsManager)
    // Fallback: If silent send fails (MIUI/ColorOS/Samsung OEM permission blocks), open url_launcher SMS composer
    for (final phone in emergencyPhones) {
      final bool sent = await NativeSmsSender.sendSms(phone: phone, message: smsBody);
      if (!sent) {
        final Uri smsUri = Uri(
          scheme: 'sms',
          path: phone,
          queryParameters: {'body': smsBody},
        );
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri, mode: LaunchMode.externalApplication);
        }
      }
    }

    // Step 3: TTS confirmation
    final confirmMsg = lang == 'hi'
        ? 'Aapke parivaar ko call ja rahi hai. Fikar mat kijiye, madad aa rahi hai.'
        : 'Calling your family now. Don\'t worry, help is on the way.';
    await tts.speakFast(confirmMsg, language: lang);
  }

  List<Widget> _buildRadialButtons(Offset center, double radius, BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final List<Map<String, dynamic>> actions = [
      {
        'icon': Icons.mic,
        'label': lang == 'hi' ? 'बात करें' : 'Talk',
        'color': Colors.blue.shade100,
        'textColor': Colors.blue.shade900,
        'route': const ChatScreen()
      },
      {
        'icon': Icons.medical_services,
        'label': lang == 'hi' ? 'दवाई' : 'Meds',
        'color': Colors.green.shade100,
        'textColor': Colors.green.shade900,
        'route': const MedsScreen()
      },
      {
        'icon': Icons.family_restroom,
        'label': lang == 'hi' ? 'परिवार' : 'Family',
        'color': Colors.purple.shade100,
        'textColor': Colors.purple.shade900,
        'route': const FamilyScreen()
      },
      {
        'icon': Icons.security,
        'label': lang == 'hi' ? 'सुरक्षा' : 'Security',
        'color': Colors.orange.shade100,
        'textColor': Colors.orange.shade900,
        'route': const SecurityScreen()
      },
      {
        'icon': Icons.warning_rounded,
        'label': lang == 'hi' ? 'सावधान' : 'Saavdhan',
        'color': Colors.yellow.shade100,
        'textColor': Colors.orange.shade900,
        'route': const ScamAlertScreen()
      },
    ];

    final int count = actions.length;
    final double buttonSize = 90;

    return List.generate(count, (index) {
      final double angle = -math.pi / 2 + (index * 2 * math.pi / count);
      final double dx = center.dx + radius * math.cos(angle) - buttonSize / 2;
      final double dy = center.dy + radius * math.sin(angle) - buttonSize / 2;

      return Positioned(
        left: dx,
        top: dy,
        child: _buildActionNode(actions[index], buttonSize, context),
      );
    });
  }

  Widget _buildActionNode(Map<String, dynamic> action, double size, BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size * 0.8,
          height: size * 0.8,
          decoration: BoxDecoration(
            color: action['color'],
            shape: BoxShape.circle,
            boxShadow: [
              const BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 4),
              )
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                HapticFeedback.lightImpact();
                SystemSound.play(SystemSoundType.click);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => action['route'])
                );
              },
              child: Icon(
                action['icon'],
                size: 36,
                color: action['textColor'],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          action['label'],
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class MantraPainter extends CustomPainter {
  final double progress;
  MantraPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    
    final Offset center = Offset(size.width / 2, size.height / 2);
    const String text = "ॐ नमः शिवाय    "; // Added more spaces for clear separation
    
    // Spiral Mantras
    final int mantrasPerRing = 12; // Fixed number to create symmetrical "spokes"
    
    for (int i = 0; i < 8; i++) {
      double radius = 80 + (i * 70) + (progress * 70);
      double rotation = progress * (math.pi / 2);
      
      double opacity = 1.0 - (radius / (size.width * 1.1));
      if (opacity < 0) opacity = 0;
      if (opacity <= 0.01) continue;
      
      final textStyle = TextStyle(
        color: Colors.orange.shade900.withValues(alpha: opacity * 0.12),
        fontSize: 12 + (radius / 30), // Font grows with radius
        fontWeight: FontWeight.bold,
      );

      final textSpan = TextSpan(text: text, style: textStyle);
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      tp.layout();

      canvas.save();
      canvas.translate(center.dx, center.dy);
      // Main rotation for the whole ring
      canvas.rotate(rotation);

      for (int j = 0; j < mantrasPerRing; j++) {
        // Each mantra is placed at a fixed angle to create the "spoke" effect
        double angle = (j * 2 * math.pi / mantrasPerRing);
        double x = radius * math.cos(angle);
        double y = radius * math.sin(angle);

        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(angle + math.pi / 2); // Follow the curve
        tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
        canvas.restore();
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant MantraPainter oldDelegate) => true;
}

/// FIX 3c: Full-screen countdown dialog before SOS triggers
class _SosCountdownDialog extends StatefulWidget {
  final VoidCallback onCancel;
  const _SosCountdownDialog({required this.onCancel});

  @override
  State<_SosCountdownDialog> createState() => _SosCountdownDialogState();
}

class _SosCountdownDialogState extends State<_SosCountdownDialog> {
  int _secondsLeft = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        if (mounted) Navigator.of(context).pop(true); // Proceed with SOS
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.red.shade900,
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emergency, color: Colors.white, size: 80),
            const SizedBox(height: 20),
            const Text(
              'SOS bheja ja raha hai...',
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              '$_secondsLeft',
              style: const TextStyle(color: Colors.yellowAccent, fontSize: 72, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onCancel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red.shade900,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('ROKO — Cancel', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

