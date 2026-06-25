import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';

class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        title: Text(lang == 'hi' ? 'Parivaar Bridge' : 'Family Bridge'),
        backgroundColor: const Color(0xFFD84315),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.family_restroom, size: 100, color: Colors.purple),
              const SizedBox(height: 30),
              Text(
                lang == 'hi' ? "Weekly Ghostwriter Summary" : "Weekly Ghostwriter Summary",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                lang == 'hi' 
                  ? "Yeh summary har Sunday aapke parivaar ko jayegi." 
                  : "This summary will be sent to your family every Sunday.",
                style: const TextStyle(fontSize: 20, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () {
                  // Logic to trigger manual summary could be added here
                }, 
                icon: const Icon(Icons.share, size: 30), 
                label: Text(
                  lang == 'hi' ? "WhatsApp se bhejein" : "Send via WhatsApp",
                  style: const TextStyle(fontSize: 20),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
