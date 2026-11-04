// Settings Screen: dark mode, font size, app version, developer contact.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/app_settings_service.dart';
import 'help_screen.dart';

class SettingsScreen extends StatelessWidget {
  final AppSettingsService settings;

  const SettingsScreen({super.key, required this.settings});

  Future<void> _launchEmail() async {
    final email = settings.developerEmail;
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'VoiceHealth Care — Support',
        'body': 'Hello VoiceHealth team,\n\nI need help with the app.\n',
      },
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not open email app');
    }
  }

  Future<void> _launchWhatsApp() async {
    final digits = settings.developerPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse(
      'https://wa.me/$digits?text=${Uri.encodeComponent('Hello VoiceHealth team, I need support.')}',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not open WhatsApp');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // App version.
          const Text(
            'About',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            subtitle: Text(settings.version),
          ),
          ListTile(
            leading: const Icon(Icons.developer_mode),
            title: const Text('Developer'),
            subtitle: Text(settings.developerName),
          ),
          const SizedBox(height: 12),

          // Developer contact.
          const Text(
            'Contact developer',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _launchEmail,
              icon: const Icon(Icons.email_outlined),
              label: const Text('Email developer'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _launchWhatsApp,
              icon: const Icon(Icons.chat_outlined),
              label: const Text('WhatsApp developer'),
            ),
          ),
          const SizedBox(height: 20),

          // Help.
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HelpScreen()),
                );
              },
              icon: const Icon(Icons.help_outline),
              label: const Text('Help — how to use the app'),
            ),
            ),
        ],
      ),
    );
  }
}
