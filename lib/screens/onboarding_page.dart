import 'package:flutter/material.dart';
import '../utils/translations.dart';

class OnboardingPage extends StatelessWidget {
  final VoidCallback onFinish;
  const OnboardingPage({super.key, required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        color: const Color(0xFFF9F3E6), // Retro Beige
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("🥭", style: TextStyle(fontSize: 100)),
            const SizedBox(height: 20),
            Text(T.get('onboarding_welcome'), 
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF3A2817))),
            const SizedBox(height: 20),
            Text(T.get('onboarding_desc'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Color(0xFF3A2817))),
            const SizedBox(height: 50),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4522A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
              ),
              onPressed: onFinish,
              child: const Text("STARTEN", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}