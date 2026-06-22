import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ScamReportWidget extends StatelessWidget {
  const ScamReportWidget({super.key});

  Future<void> _triggerRealSOS(BuildContext context) async {
    // This is the real SOS pathway. In a production app, this would use a globally
    // configured emergency contact. Here we use a standard emergency SMS intent.
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: '100', // Or a family member's number
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
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      child: ElevatedButton.icon(
        onPressed: () => _triggerRealSOS(context),
        icon: const Icon(Icons.report_problem, size: 36, color: Colors.white),
        label: const Text(
          'Mujhe Dhokha Hua',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade800,
          padding: const EdgeInsets.symmetric(vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
