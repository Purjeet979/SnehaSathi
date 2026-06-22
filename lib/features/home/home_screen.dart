import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/providers.dart';
import '../../data/local/user_preferences_repository.dart';
import 'dart:math' as math;
import '../chat/chat_screen.dart';
import '../medication/meds_screen.dart';
import '../family/family_screen.dart';
import '../security/security_screen.dart';
import '../scam_alert/scam_alert_screen.dart';

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

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aapki Details'),
        content: Column(
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
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await userPrefs.setDadiName(nameCtrl.text);
              await userPrefs.setEmergencyContact(phoneCtrl.text);
              if (ctx.mounted) Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Save'),
          ),
        ],
      ),
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
        title: Row(
          children: [
            Image.asset(
              'assets/images/sneh_saathi_logo.png',
              width: 70,
              height: 70,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.favorite, color: Colors.red.shade700, size: 50),
            ),
            const SizedBox(width: 12),
            Column(
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
                ),
                Text(
                  selectedLang == 'hi' ? 'आपका प्यारा साथी' : 'Your Caring Companion',
                  style: TextStyle(
                    color: Colors.brown.shade400,
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.brown, size: 28),
                      onPressed: () => _showSettingsDialog(context, ref),
                    ),
                    ToggleButtons(
                      isSelected: [selectedLang == 'hi', selectedLang == 'en'],
                      onPressed: (index) {
                        ref.read(languageProvider.notifier).setLanguage(index == 0 ? 'hi' : 'en');
                      },
                      borderRadius: BorderRadius.circular(12),
                      constraints: const BoxConstraints(minHeight: 28.0, minWidth: 36.0),
                      fillColor: Colors.red.shade100,
                      selectedColor: Colors.red.shade900,
                      children: const [
                        Text('हिंदी', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('EN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                if (selectedLang == 'hi')
                  DropdownButton<String>(
                    value: selectedDialect,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
                    isDense: true,
                    style: const TextStyle(color: Colors.brown, fontSize: 13),
                    items: ['Hindi', 'Bhojpuri', 'Marwari', 'Gujarati'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        ref.read(dialectProvider.notifier).setDialect(newValue);
                      }
                    },
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
                const SizedBox(height: 30),
                Text(
                  selectedLang == 'hi' ? 'नमस्ते, ${userPrefs.dadiName}!' : 'Namaste, ${userPrefs.dadiName}!',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    backgroundColor: Colors.white.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  selectedLang == 'hi' ? 'आज मैं आपकी क्या मदद कर सकता हूँ?' : 'How can I help you today?',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    backgroundColor: Colors.white.withValues(alpha: 0.5),
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
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
        onPressed: () async {
          final Uri smsUri = Uri(
            scheme: 'sms',
            path: '100',
            queryParameters: <String, String>{
              'body': 'EMERGENCY: Mujhe madad chahiye! (Sneh Saathi SOS)',
            },
          );
          if (await canLaunchUrl(smsUri)) {
            await launchUrl(smsUri);
          }
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

