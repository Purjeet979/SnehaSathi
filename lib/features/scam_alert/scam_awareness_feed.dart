import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';

class ScamAwarenessFeed extends ConsumerWidget {
  const ScamAwarenessFeed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final dialect = ref.watch(dialectProvider);

    String feedTitle = lang == 'en' 
        ? "Today's Safety Alerts"
        : (dialect == 'Marathi' ? "आजचे धोक्याचे अलर्ट्स" : "आज के सुरक्षा अलर्ट्स");

    final alerts = lang == 'en' ? [
      {'title': 'Bank KYC Scam', 'desc': 'No bank asks for KYC updates over phone. Never share your PIN or OTP.'},
      {'title': 'Fake Lottery Scam', 'desc': 'If you didn\'t buy a ticket, you cannot win a lottery.'},
      {'title': 'Parcel Blocked Scam', 'desc': 'Fake couriers ask for money to release blocked packages.'},
      {'title': 'Digital Arrest Scam', 'desc': 'Police never demand money transfer over video/phone calls.'},
    ] : (dialect == 'Marathi' ? [
      {'title': 'बँक KYC स्कॅम', 'desc': 'कोणतीही बँक फोनवर KYC अपडेट मागत नाही. आपला PIN किंवा OTP शेअर करू नका.'},
      {'title': 'लॉटरी जिंकण्याचे आमिष', 'desc': 'जर तुम्ही तिकीट खरेदी केले नसेल, तर लॉटरी लागू शकत नाही.'},
      {'title': 'पार्सल ब्लॉक स्कॅम', 'desc': 'नक्कली कुरिअरवाले पार्सल सोडवण्यासाठी पैसे मागायला येतात.'},
      {'title': 'पोलिस/CBI डिजिटल अर्रेस्ट', 'desc': 'पोलिस फोनवर धमकावून पैसे ट्रान्सफर करायला सांगत नाहीत.'},
    ] : [
      {'title': 'बैंक KYC स्कैम', 'desc': 'कोई भी बैंक फोन पर KYC अपडेट नहीं मांगता। अपना PIN या OTP कभी शेयर न करें।'},
      {'title': 'लॉटरी जीतने का झांसा', 'desc': 'अगर आपने टिकट नहीं खरीदी, तो लॉटरी कभी नहीं लग सकती।'},
      {'title': 'पार्सल ब्लॉक स्कैम', 'desc': 'नकली कूरियर वाले पार्सल छुड़ाने के नाम पर पैसे मांगते हैं।'},
      {'title': 'डिजिटल अरेस्ट डरावा', 'desc': 'पुलिस फोन पर डराकर पैसे ट्रांसफर करने को कभी नहीं कहती।'},
    ]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(feedTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...alerts.map((alert) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          color: Colors.yellow.shade50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.deepOrange),
                    const SizedBox(width: 8),
                    Expanded(child: Text(alert['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                  ],
                ),
                const SizedBox(height: 8),
                Text(alert['desc']!, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        )),
      ],
    );
  }
}
