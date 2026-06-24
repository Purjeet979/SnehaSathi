import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/providers.dart';
import '../../data/local/database.dart';
import '../../core/settings/user_settings.dart';

class MedsScreen extends ConsumerStatefulWidget {
  const MedsScreen({super.key});

  @override
  ConsumerState<MedsScreen> createState() => _MedsScreenState();
}

class _MedsScreenState extends ConsumerState<MedsScreen> {
  List<Medication> _meds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAndCheckRollover();
  }

  Future<void> _loadAndCheckRollover() async {
    final db = ref.read(databaseProvider);
    final settings = ref.read(userSettingsProvider);
    final prefs = await SharedPreferences.getInstance();
    
    // Day Rollover Logic
    final now = DateTime.now();
    // If current time is past dayStartHour, "today" started today at dayStartHour.
    // If it's before dayStartHour, "today" started yesterday at dayStartHour.
    final currentDayBoundary = DateTime(
      now.year, now.month, now.hour >= settings.dayStartHour ? now.day : now.day - 1, 
      settings.dayStartHour
    );
    
    final lastResetMs = prefs.getInt('lastMedsResetMs') ?? 0;
    
    if (lastResetMs < currentDayBoundary.millisecondsSinceEpoch) {
      // Need to reset all meds for the new day
      final allMeds = await db.getAllMedications();
      for (var med in allMeds) {
        if (med.isTaken) {
          await db.updateMedication(med.copyWith(isTaken: false));
        }
      }
      await prefs.setInt('lastMedsResetMs', now.millisecondsSinceEpoch);
    }
    
    _refreshMeds();
  }

  Future<void> _refreshMeds() async {
    final db = ref.read(databaseProvider);
    final meds = await db.getAllMedications();
    if (mounted) {
      setState(() {
        _meds = meds;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleMed(Medication med) async {
    final db = ref.read(databaseProvider);
    final lang = ref.read(languageProvider);
    await db.updateMedication(med.copyWith(isTaken: !med.isTaken));
    
    if (!med.isTaken) { // Because we just toggled it to true
      final msg = lang == 'hi' ? "Shabash dadi, dawai kha li!" : "Well done Dadi, you took your medicine!";
      ref.read(ttsManagerProvider).speakFast(msg, language: lang);
    }
    _refreshMeds();
  }

  Future<void> _deleteMed(Medication med) async {
    final lang = ref.read(languageProvider);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lang == 'hi' ? 'Dawai Hatayein?' : 'Remove Medicine?'),
        content: Text(lang == 'hi' 
            ? 'Kya aap "${med.name}" ko list se hatana chahte hain?' 
            : 'Do you want to remove "${med.name}" from the list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), 
            child: Text(lang == 'hi' ? 'Nahi' : 'No')
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
            child: Text(lang == 'hi' ? 'Haan, Hatayein' : 'Yes, Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final db = ref.read(databaseProvider);
      await db.deleteMedication(med);
      _refreshMeds();
    }
  }

  // Parses voice input to add a med, e.g., "Subah Paracetamol"
  void _startVoiceAddFlow() {
    final lang = ref.read(languageProvider);
    final prompt = lang == 'hi' ? "Kaunsi dawai aur kab khani hai?" : "Which medicine and when to take it?";
    ref.read(ttsManagerProvider).speakFast(prompt, language: lang);
    
    ref.read(voiceInputProvider).startListening(
      onStart: () {},
      onStop: () {},
      onResult: (text) async {
        if (text.trim().isEmpty) return;
        
        // Prevent error messages from being added as meds
        if (text.contains("issue") || text.contains("bol sakte")) return;
        
        String timeToTake = 'Dopahar';
        final lower = text.toLowerCase();
        if (lang == 'hi') {
          if (lower.contains('subah') || lower.contains('morning')) {
            timeToTake = 'Subah';
          } else if (lower.contains('shaam') || lower.contains('evening')) {
            timeToTake = 'Shaam';
          } else if (lower.contains('raat') || lower.contains('night')) {
            timeToTake = 'Raat';
          }
        } else {
          if (lower.contains('morning')) {
            timeToTake = 'Subah';
          } else if (lower.contains('afternoon')) {
            timeToTake = 'Dopahar';
          } else if (lower.contains('evening')) {
            timeToTake = 'Shaam';
          } else if (lower.contains('night')) {
            timeToTake = 'Raat';
          }
        }
        
        final db = ref.read(databaseProvider);
        await db.addMedication(MedicationsCompanion.insert(
          name: text,
          timeToTake: timeToTake,
        ));
        
        final confirmMsg = lang == 'hi' ? "Dawai add ho gayi" : "Medicine added successfully";
        ref.read(ttsManagerProvider).speakFast(confirmMsg, language: lang);
        _refreshMeds();
      },
      languageCode: lang == 'hi' ? 'hi-IN' : 'en-IN'
    );
  }

  void _showManualAddDialog() {
    final lang = ref.read(languageProvider);
    final nameCtrl = TextEditingController();
    String selectedTime = 'Subah';
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(lang == 'hi' ? 'Dawai Add Karein' : 'Add Medicine'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: lang == 'hi' ? 'Dawai ka naam' : 'Medicine Name', 
                  border: const OutlineInputBorder()
                ),
              ),
              const SizedBox(height: 16),
              DropdownButton<String>(
                value: selectedTime,
                isExpanded: true,
                items: ['Subah', 'Dopahar', 'Shaam', 'Raat'].map((t) {
                  String label = t;
                  if (lang == 'en') {
                    if (t == 'Subah') {
                      label = 'Morning';
                    } else if (t == 'Dopahar') {
                      label = 'Afternoon';
                    } else if (t == 'Shaam') {
                      label = 'Evening';
                    } else if (t == 'Raat') {
                      label = 'Night';
                    }
                  }
                  return DropdownMenuItem(value: t, child: Text(label));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => selectedTime = val);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(lang == 'hi' ? 'Cancel' : 'Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;
                final db = ref.read(databaseProvider);
                await db.addMedication(MedicationsCompanion.insert(
                  name: nameCtrl.text,
                  timeToTake: selectedTime,
                ));
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                _refreshMeds();
              },
              child: Text(lang == 'hi' ? 'Add' : 'Add'),
            )
          ],
        ),
      )
    );
  }

  Widget _buildTimeGroup(String title, IconData icon, Color iconColor, List<Medication> medsForTime, String lang) {
    if (medsForTime.isEmpty) return const SizedBox.shrink();
    
    String displayTitle = title;
    if (lang == 'en') {
      if (title == 'Subah') {
        displayTitle = 'Morning';
      } else if (title == 'Dopahar') {
        displayTitle = 'Afternoon';
      } else if (title == 'Shaam') {
        displayTitle = 'Evening';
      } else if (title == 'Raat') {
        displayTitle = 'Night';
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: iconColor),
              const SizedBox(width: 12),
              Text(displayTitle, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
        ),
        ...medsForTime.map((med) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: () => _toggleMed(med),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Transform.scale(
                    scale: 2.0,
                    child: Checkbox(
                      value: med.isTaken,
                      onChanged: (val) => _toggleMed(med),
                      activeColor: Colors.green,
                      shape: const CircleBorder(),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Text(
                      med.name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        decoration: med.isTaken ? TextDecoration.lineThrough : null,
                        color: med.isTaken ? Colors.grey : Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red.shade300, size: 30),
                    onPressed: () => _deleteMed(med),
                  ),
                ],
              ),
            ),
          ),
        )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final subahMeds = _meds.where((m) => m.timeToTake == 'Subah').toList();
    final dopaharMeds = _meds.where((m) => m.timeToTake == 'Dopahar').toList();
    final shaamMeds = _meds.where((m) => m.timeToTake == 'Shaam').toList();
    final raatMeds = _meds.where((m) => m.timeToTake == 'Raat').toList();

    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: Text(
          lang == 'hi' ? 'Dawai Yaad Dilayein' : 'Medicine Reminder', 
          style: const TextStyle(fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: _meds.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.medical_services_outlined, size: 100, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  lang == 'hi' ? 'Koi dawai add nahi hai.' : 'No medicines added.', 
                  style: const TextStyle(fontSize: 24, color: Colors.grey)
                ),
              ],
            ),
          )
        : ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildTimeGroup('Subah', Icons.wb_sunny, Colors.orange, subahMeds, lang),
              _buildTimeGroup('Dopahar', Icons.wb_sunny_outlined, Colors.orangeAccent, dopaharMeds, lang),
              _buildTimeGroup('Shaam', Icons.wb_cloudy, Colors.blueGrey, shaamMeds, lang),
              _buildTimeGroup('Raat', Icons.nightlight_round, Colors.indigo, raatMeds, lang),
              const SizedBox(height: 100), // Space for FAB
            ],
          ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FloatingActionButton.extended(
              heroTag: 'manualAdd',
              onPressed: _showManualAddDialog,
              backgroundColor: Colors.white,
              foregroundColor: Colors.green.shade800,
              icon: const Icon(Icons.keyboard),
              label: Text(lang == 'hi' ? 'Type Karein' : 'Type Entry'),
            ),
            FloatingActionButton.extended(
              heroTag: 'voiceAdd',
              onPressed: _startVoiceAddFlow,
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.mic, size: 36),
              label: Text(
                lang == 'hi' ? 'Bolkar Add Karein' : 'Add by Voice', 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
              ),
            ),
          ],
        ),
      ),
    );
  }
}
