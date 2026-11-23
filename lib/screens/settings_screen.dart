// Settings Screen: font size, TTS toggle, app version, developer contact, and tutorial.
// Persisted in SharedPreferences so choices survive restarts.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/app_settings_service.dart';
import 'help_screen.dart';
import '../widgets/onboarding_tutorial.dart';

class SettingsScreen extends StatefulWidget {
  final AppSettingsService settings;

  const SettingsScreen({super.key, required this.settings});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _ttsEnabled;

  @override
  void initState() {
    super.initState();
    _ttsEnabled = widget.settings.ttsEnabled;
  }

  Future<void> _launchEmail() async {
    final email = widget.settings.developerEmail;
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
    final digits = widget.settings.developerPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse(
      'https://wa.me/$digits?text=${Uri.encodeComponent('Hello VoiceHealth team, I need support.')}',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not open WhatsApp');
    }
  }

  Future<void> _launchDeveloperSite() async {
    const String developerSiteUrl = 'https://prop-industries.vercel.app/';
    final uri = Uri.parse(developerSiteUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not open developer site');
    }
  }

  // 3 intro slides (same ones used in onboarding).
  List<TutorialSlide> _tutorialSlides = [
    TutorialSlide(
      image: 'assets/intro/intro1.png',
      heading: 'Welcome to VoiceHealth',
      description:
          'Your personal healthcare assistant — ask health questions by voice or text and get guidance from the clinical knowledge base.',
    ),
    TutorialSlide(
      image: 'assets/intro/intro2.png',
      heading: 'Get Trusted Advice',
      description:
          'Search our clinical knowledge base for conditions, first aid, nutrition and more. Find answers quickly and reliably.',
    ),
    TutorialSlide(
      image: 'assets/intro/intro3.png',
      heading: 'Book with Confidence',
      description:
          'Find doctors, book appointments, and manage your health — all in one app. View doctor profiles and schedule consultations.',
    ),
  ];

  void _showTutorialInSettings() {
    // Show the onboarding tutorial in "settings mode":
    // - No Skip button
    // - Back button on first slide
    // - Finish button on last slide
    // - Return to Settings when finished
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OnboardingTutorial(
          slides: _tutorialSlides,
          showSkip: false, // No Skip in settings mode
          onBack: () => Navigator.pop(context), // Return to Settings
          onFinish: () => Navigator.pop(context), // Return to Settings
          onNext: () {}, // Not used; navigation handled by page change
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // TTS toggle.
          const Text(
            'Voice Output',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            title: const Text('Read health advice aloud'),
            subtitle: const Text(
              'Speaks the health advice automatically when results appear.',
            ),
            value: _ttsEnabled,
            onChanged: (val) async {
              setState(() => _ttsEnabled = val ?? false);
              await widget.settings.setTtsEnabled(_ttsEnabled);
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 8),

          // How to Use the App tutorial.
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('How to Use the App'),
            subtitle: const Text('View introductory slides'),
            onTap: () {
              _showTutorialInSettings();
            },
          ),
          const SizedBox(height: 20),

          // App version.
          const Text(
            'About',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            subtitle: Text(widget.settings.version),
          ),
          ListTile(
            leading: const Icon(Icons.developer_mode),
            title: const Text('Developer'),
            subtitle: Text(widget.settings.developerName),
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
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _launchDeveloperSite,
              icon: const Icon(Icons.open_in_new_outlined),
              label: const Text('Meet the developer'),
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