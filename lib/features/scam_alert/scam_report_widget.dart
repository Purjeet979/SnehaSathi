import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/providers.dart';

class ScamReportWidget extends ConsumerWidget {
  const ScamReportWidget({super.key});

  Future<void> _triggerRealSOS(BuildContext context) async {
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: '100',
      queryParameters: <String, String>{
        'body': 'EMERGENCY: Mujhe dhokha (scam) hua hai ya main khatre mein hu. Kripya turant sampark karein!',
      },
    );
    
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open SMS app to send SOS.', style: TextStyle(fontSize: 18))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final dialect = ref.watch(dialectProvider);

    String btnLabel = lang == 'en' 
        ? 'I Was Scammed (Report SOS)'
        : (dialect == 'Marathi' ? 'माझी फसवणूक झाली (SOS)' : 'मुझे धोखा हुआ (स्कैम SOS)');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      child: ElevatedButton.icon(
        onPressed: () => _triggerRealSOS(context),
        icon: const Icon(Icons.report_problem, size: 36, color: Colors.white),
        label: Text(
          btnLabel,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade800,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
