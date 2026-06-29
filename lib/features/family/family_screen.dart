import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/providers.dart';
import '../../data/local/database.dart';
import '../../core/workers/work_manager_helper.dart';

class FamilyScreen extends ConsumerStatefulWidget {
  const FamilyScreen({super.key});

  @override
  ConsumerState<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends ConsumerState<FamilyScreen> {
  String _frequency = 'Daily';

  @override
  void initState() {
    super.initState();
    _loadFrequency();
  }

  Future<void> _loadFrequency() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _frequency = prefs.getString('summary_frequency') ?? 'Daily';
    });
  }

  Future<void> _setFrequency(String freq) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('summary_frequency', freq);
    setState(() {
      _frequency = freq;
    });
    // Reschedule worker with new frequency
    await WorkManagerHelper.scheduleGhostwriterWorker();
  }

  Future<void> _shareDigest(DailyDigestInfo info, bool isHindi) async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('emergency_contact_1_phone') ?? '';
    final digestText = info.toFormattedDigest(isHindi: isHindi);

    final msg = Uri.encodeComponent(digestText);
    final url = phone.isNotEmpty
        ? Uri.parse('https://wa.me/$phone?text=$msg')
        : Uri.parse('whatsapp://send?text=$msg');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final dialect = ref.watch(dialectProvider);
    final isHindi = lang == 'hi';
    final db = ref.watch(databaseProvider);

    String appBarTitle = isHindi ? (dialect == 'Marathi' ? 'परिवार ब्रिज — डैशबोर्ड' : 'परिवार ब्रिज — डैशबोर्ड') : 'Family Bridge — Dashboard';
    String bannerTitle = isHindi ? (dialect == 'Marathi' ? 'कुटुंब शांतता डैशबोर्ड' : 'परिवार पीस-ऑफ़-माइंड डैशबोर्ड') : 'Family Peace-of-Mind Dashboard';
    String bannerSub = isHindi ? (dialect == 'Marathi' ? 'गोपनीयता न भंग करता, रोजचे सुरक्षित अपडेट्स' : 'बिना प्राइवेसी तोड़े, हर दिन के सेफ़ अपडेट्स') : 'Read-only updates without invading privacy';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        title: Text(appBarTitle),
        backgroundColor: const Color(0xFFD84315),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<SharedPreferences>(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          final elderName = snapshot.data?.getString('elder_name') ?? snapshot.data?.getString('dadi_name') ?? 'Dadi';

          return FutureBuilder<DailyDigestInfo>(
            future: db.getDailyDigestInfo(elderName),
            builder: (context, digestSnapshot) {
              if (!digestSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final info = digestSnapshot.data!;

              String sectionTitle = isHindi 
                  ? (dialect == 'Marathi' ? "आजचा दैनिक हाल-चाल ($elderName)" : "आज का दैनिक हाल-चाल ($elderName)") 
                  : "Today's Daily Digest ($elderName)";

              String actTitle = isHindi ? (dialect == 'Marathi' ? 'बातचीत (ॲक्टिव्हिटी)' : 'बातचीत (गतिविधि)') : 'Conversation Activity';
              String actVal = info.talkMinutes == 0
                  ? (isHindi ? (dialect == 'Marathi' ? 'अजून संभाषण झाले नाही' : 'अभी बात नहीं हुई') : 'No calls yet today')
                  : (isHindi ? (dialect == 'Marathi' ? '${info.talkMinutes} मिनिटे' : '${info.talkMinutes} मिनट') : '${info.talkMinutes} mins');
              String actSub = isHindi ? (dialect == 'Marathi' ? 'AI साथीसोबत घालवलेला वेळ' : 'AI साथी के साथ बिताया गया समय') : 'Time spent conversing today';

              String medTitle = isHindi ? (dialect == 'Marathi' ? 'औषधे (मेडिसिन स्टेटस)' : 'दवाइयां (मेडिसिन स्टेटस)') : 'Medication Status';
              String medVal = info.totalMeds == 0
                  ? (isHindi ? (dialect == 'Marathi' ? 'कोणतेही औषध निश्चित नाही' : 'कोई दवाई scheduled नहीं') : 'No meds scheduled')
                  : (isHindi ? (dialect == 'Marathi' ? '${info.takenMeds} / ${info.totalMeds} घेतलेली' : '${info.takenMeds} / ${info.totalMeds} ली गई') : '${info.takenMeds} / ${info.totalMeds} taken');
              String medSub = isHindi ? (dialect == 'Marathi' ? 'वेळेवर घेतलेली औषधे' : 'समय पर ली गई दवाइयां') : 'Scheduled doses confirmed';

              String secTitle = isHindi ? (dialect == 'Marathi' ? 'सुरक्षा (स्कॅम शील्ड)' : 'सुरक्षा (स्कैम शील्ड)') : 'Safety Check';
              String secVal = isHindi ? (dialect == 'Marathi' ? 'सुरक्षित (0 धोके)' : 'सुरक्षित (0 खतरे)') : 'Clean (0 Threats)';
              String secSub = isHindi ? (dialect == 'Marathi' ? 'कोणताही फ्रॉड कॉल किंवा मेसेज नाही' : 'कोई फ्रॉड कॉल या मैसेज नहीं मिला') : 'No scam attempts detected';

              String freqTitle = isHindi ? (dialect == 'Marathi' ? 'ऑटो-समरी वारंवारता' : 'ऑटो-समरी फ़्रीक्वेंसी') : 'Auto-Summary Frequency';
              String freqSub = isHindi ? (dialect == 'Marathi' ? 'व्हॉट्सॲप अपडेट्स किती वेळा पाठवायचे?' : 'व्हाट्सएप अपडेट्स कितनी बार भेजें?') : 'How often should updates be sent to family?';
              String chipDaily = isHindi ? (dialect == 'Marathi' ? 'रोज (दैनिक)' : 'रोज़ाना (दैनिक)') : 'Daily Digest';
              String chipWeekly = isHindi ? (dialect == 'Marathi' ? 'दर आठवड्याला (साप्ताहिक)' : 'हर हफ्ते (साप्ताहिक)') : 'Weekly Digest';

              String btnText = isHindi ? (dialect == 'Marathi' ? "व्हॉट्सॲप डायजेस्ट पाठवा" : "व्हाट्सएप डाइजेस्ट भेजें") : "Forward Digest via WhatsApp";

              return ListView(
                padding: const EdgeInsets.all(20.0),
                children: [
                  // Header Banner
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.deepOrange.shade700, Colors.orange.shade800],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.family_restroom, size: 60, color: Colors.white),
                        const SizedBox(height: 12),
                        Text(
                          bannerTitle,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          bannerSub,
                          style: const TextStyle(fontSize: 14, color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Digest Cards Grid
                  Text(
                    sectionTitle,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown.shade800),
                  ),
                  const SizedBox(height: 12),

                  // 1. Conversation Duration
                  _buildMetricCard(
                    icon: Icons.forum_rounded,
                    iconColor: Colors.blue.shade700,
                    title: actTitle,
                    value: actVal,
                    subtitle: actSub,
                  ),
                  const SizedBox(height: 12),

                  // 2. Medication Adherence
                  _buildMetricCard(
                    icon: Icons.medical_services_rounded,
                    iconColor: Colors.green.shade700,
                    title: medTitle,
                    value: medVal,
                    subtitle: medSub,
                  ),
                  const SizedBox(height: 12),

                  // 3. Scam / Security Checks
                  _buildMetricCard(
                    icon: Icons.shield_rounded,
                    iconColor: Colors.orange.shade800,
                    title: secTitle,
                    value: secVal,
                    subtitle: secSub,
                  ),
                  const SizedBox(height: 24),

                  // Configurable Frequency Selection Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.settings_suggest, color: Colors.brown),
                              const SizedBox(width: 8),
                              Text(
                                freqTitle,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            freqSub,
                            style: const TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ChoiceChip(
                                  label: Center(child: Text(chipDaily)),
                                  selected: _frequency == 'Daily',
                                  onSelected: (selected) {
                                    if (selected) _setFrequency('Daily');
                                  },
                                  selectedColor: Colors.deepOrange.shade100,
                                  labelStyle: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _frequency == 'Daily' ? Colors.deepOrange.shade900 : Colors.black87,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ChoiceChip(
                                  label: Center(child: Text(chipWeekly)),
                                  selected: _frequency == 'Weekly',
                                  onSelected: (selected) {
                                    if (selected) _setFrequency('Weekly');
                                  },
                                  selectedColor: Colors.deepOrange.shade100,
                                  labelStyle: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _frequency == 'Weekly' ? Colors.deepOrange.shade900 : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // WhatsApp Share Button
                  ElevatedButton.icon(
                    onPressed: () => _shareDigest(info, isHindi),
                    icon: const Icon(Icons.share, size: 28),
                    label: Text(
                      btnText,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
