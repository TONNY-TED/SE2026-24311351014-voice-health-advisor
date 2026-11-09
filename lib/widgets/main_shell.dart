// Main shell: persistent bottom navigation over the five main sections.
// Roadmap stays reachable from Settings so all six destinations keep access.
// Tab switches fade in; each tab keeps its own state (e.g. typed text).

import 'package:flutter/material.dart';

import '../main.dart' show HomeScreen;
import '../services/app_settings_service.dart';
import '../screens/doctors_screen.dart';
import '../screens/history_screen.dart';
import '../screens/knowledge_screen.dart';
import '../screens/profile_screen.dart';

class MainShell extends StatefulWidget {
  final AppSettingsService settings;
  final VoidCallback? onLoggedOut;

  const MainShell({
    super.key,
    required this.settings,
    this.onLoggedOut,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // Currently selected tab (0 = Voice Query).
  int _index = 0;

  // Disclaimer shows once per app open after login.
  bool _disclaimerShown = false;

  @override
  void initState() {
    super.initState();
    // Show the medical disclaimer once the app opens after login.
    WidgetsBinding.instance.addPostFrameCallback((_) => _showDisclaimer());
  }

  // Startup notice: app is information only, not a diagnosis.
  Future<void> _showDisclaimer() async {
    if (_disclaimerShown || !mounted) return;
    _disclaimerShown = true;
    await showDialog<void>(
      context: context,
      // User must acknowledge before continuing.
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Please note'),
        content: const Text(
          'VoiceHealth provides general health and wellness information only. '
          'It is not a diagnosis app. If you are unsure about your health, '
          'please visit a qualified health worker.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tab screens in bottom-nav order; Profile needs settings + logout callback.
    final tabs = [
      HomeScreen(settings: widget.settings),
      const KnowledgeScreen(),
      const HistoryScreen(),
      const DoctorsScreen(),
      ProfileScreen(
        settings: widget.settings,
        onLoggedOut: widget.onLoggedOut,
      ),
    ];
    return Scaffold(
      // AnimatedSwitcher fades between tabs; IndexedStack keeps tab state.
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: IndexedStack(
          key: ValueKey<int>(_index),
          index: _index,
          children: tabs,
        ),
      ),
      // Material 3 bar; accent highlight comes from the app theme.
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.mic_outlined),
            selectedIcon: Icon(Icons.mic),
            label: 'Voice Query',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Knowledge',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.medical_services_outlined),
            selectedIcon: Icon(Icons.medical_services),
            label: 'Doctors',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
