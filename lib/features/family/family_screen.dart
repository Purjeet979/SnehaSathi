import 'package:flutter/material.dart';

class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Parivaar Bridge'),
        backgroundColor: const Color(0xFFD84315),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.family_restroom, size: 80, color: Colors.purple),
            const SizedBox(height: 20),
            Text(
              "Weekly Ghostwriter Summary",
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {}, 
              icon: const Icon(Icons.share), 
              label: const Text("Send via WhatsApp")
            )
          ],
        ),
      ),
    );
  }
}
