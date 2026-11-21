// Help Screen: how to use VoiceHealth — read-only guide.

import 'package:material_ui/material_ui.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'How to use VoiceHealth',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'VoiceHealth gives general health guidance by voice or text. '
            'It is information only — not a medical diagnosis.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),

          _step(context, 1, 'Create your account',
              'Register once, then log in. Your profile and history are saved on this device.'),
          _step(context, 2, 'Ask a health question',
              'Tap the microphone and speak, or type your question (e.g. “sleep”, “water”, “malaria”).'),
          _step(context, 3, 'Read the advice',
              'You get topic-based guidance with tips and “see a doctor if” warnings, plus the source.'),
          _step(context, 4, 'Check your history',
              'Use the History tab to see past questions. You can clear your history anytime.'),
          _step(context, 5, 'Book a doctor',
              'Open the Doctors tab, view a doctor’s profile, and book an appointment by email or WhatsApp.'),
          _step(context, 6, 'Stay safe',
              'If you see “EMERGENCY”, seek care straight away. When unsure, visit a qualified health worker.'),
          const SizedBox(height: 24),

          Card(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Important',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text(
                    'VoiceHealth provides general health and wellness '
                    'information only. It does not diagnose medical conditions '
                    'or prescribe medication. Always consult a qualified '
                    'health worker if you are unsure.',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _step(BuildContext context, int n, String title, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text('$n',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(text, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
