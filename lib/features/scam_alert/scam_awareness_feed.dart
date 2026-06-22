import 'package:flutter/material.dart';

class ScamAwarenessFeed extends StatelessWidget {
  const ScamAwarenessFeed({super.key});

  @override
  Widget build(BuildContext context) {
    final alerts = [
      {'title': 'Bank KYC Scam', 'desc': 'Koi bank phone par KYC update nahi maangta. Apna PIN share na karein.'},
      {'title': 'Lottery Jeetne ka Jhansa', 'desc': 'Agar aapne ticket nahi kharidi, toh lottery nahi lag sakti.'},
      {'title': 'Parcel Blocked Scam', 'desc': 'Fake courier wale paise maangte hain parcel chudane ke liye.'},
      {'title': 'Police/CBI Arrest Scam', 'desc': 'Police phone par dhamkakar paise transfer karne ko nahi kehti.'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Aaj Ke Alerts', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
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
        )).toList(),
      ],
    );
  }
}
