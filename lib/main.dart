// Import Flutter Material package
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:material_ui/material_ui.dart';

// Import Speech Recognition Module (Week 2: Voice Recognition)
import 'package:healthcare_assistant/services/speech_service.dart';
import 'package:healthcare_assistant/services/tts_service.dart';

// Import Authentication Module (register / login / saved profile)
import 'package:healthcare_assistant/services/auth_service.dart';
import 'package:healthcare_assistant/services/app_settings_service.dart';
import 'package:healthcare_assistant/services/health_service.dart';
import 'package:healthcare_assistant/services/knowledge_base_service.dart';
import 'package:healthcare_assistant/services/local_db_service.dart';
import 'package:healthcare_assistant/services/nlp_service.dart';
import 'package:healthcare_assistant/screens/login_screen.dart';
import 'package:healthcare_assistant/screens/sources_screen.dart';
import 'package:healthcare_assistant/screens/history_screen.dart';
import 'package:healthcare_assistant/screens/profile_screen.dart';
import 'package:healthcare_assistant/widgets/main_shell.dart';
import 'package:healthcare_assistant/widgets/onboarding_tutorial.dart';


// Application entry point
void main() {
  runApp(HealthcareAssistantApp(settings: AppSettingsService()));
}

// Main Application Widget (loads persisted theme + font scale first).
class HealthcareAssistantApp extends StatefulWidget {
  final AppSettingsService? settings;

  HealthcareAssistantApp({super.key, this.settings});

  @override
  State<HealthcareAssistantApp> createState() => _HealthcareAssistantAppState();
}

class _HealthcareAssistantAppState extends State<HealthcareAssistantApp> {
  final AppSettingsService _settings = AppSettingsService();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _settings.load().then((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use Directionality to provide text direction before MaterialApp (Chrome web compatibility)
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'VoiceHealth',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          cardTheme: const CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
        home: AuthGate(settings: _settings),
      ),
    );
  }
}

// Auth gate: checks saved session on startup and switches screens.
class AuthGate extends StatefulWidget {
  final AppSettingsService settings;

  const AuthGate({super.key, required this.settings});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _auth = AuthService();
  bool? _loggedIn;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final user = await _auth.currentUser();
    setState(() => _loggedIn = user != null);
  }

  @override
  Widget build(BuildContext context) {
    if (_loggedIn == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loggedIn!) {
      return MainShell(
        settings: widget.settings,
        onLoggedOut: () => setState(() => _loggedIn = false),
      );
    }

    // Show onboarding tutorial once before login; skip if already seen.
    if (!widget.settings.introShown) {
      return OnboardingTutorial(
        slides: [
          TutorialSlide.withIndex(
            image: 'assets/intro/intro1.png',
            heading: 'Welcome to VoiceHealth',
            description:
                'Your personal healthcare assistant — ask health questions by voice or text and get guidance from the clinical knowledge base.',
            index: 0,
          ),
          TutorialSlide.withIndex(
            image: 'assets/intro/intro2.png',
            heading: 'Get Trusted Advice',
            description:
                'Search our clinical knowledge base for conditions, first aid, nutrition and more. Find answers quickly and reliably.',
            index: 1,
          ),
          TutorialSlide.withIndex(
            image: 'assets/intro/intro3.png',
            heading: 'Book with Confidence',
            description:
                'Find doctors, book appointments, and manage your health — all in one app. View doctor profiles and schedule consultations.',
            index: 2,
          ),
        ],
        showSkip: true,
        onSkip: () {
          widget.settings.setIntroShown(true);
          setState(() {});
        },
        onNext: () {
          // onNext is handled by page change; finish called when last slide reached
        },
        onBack: () {},
        onFinish: () {
          widget.settings.setIntroShown(true);
          setState(() {});
        },
      );
    }

    return LoginScreen(onLoggedIn: () => setState(() => _loggedIn = true));
  }
}

// Home Screen Widget: Voice Query tab (main health assistant).
class HomeScreen extends StatefulWidget {
  final AppSettingsService settings;

  const HomeScreen({super.key, required this.settings});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// Home Screen State: handles Week 2 voice flow
class _HomeScreenState extends State<HomeScreen> {
  final AuthService _auth = AuthService();
  final SpeechService _speechService = SpeechService();
  final TtsService _ttsService = TtsService();

  bool isListening = false;
  String recognizedText = "No voice input yet";
  String healthAdvice = "Your health advice will appear here";
  final TextEditingController _textController = TextEditingController();

  List<KbEntry> _kbEntries = [];
  String _detectedLabel = '';
  String _userName = '';
  String _userEmail = '';
  bool _ttsEnabled = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
    _loadProfile();
    _loadKnowledgeBase();
  }

  Future<void> _initTts() async {
    final prefsLoaded = widget.settings.ttsEnabled;
    setState(() => _ttsEnabled = prefsLoaded);
    await _ttsService.initialize();
    _ttsService.setEnabled(prefsLoaded);
  }

  Future<void> _loadKnowledgeBase() async {
    try {
      final entries = await KnowledgeBaseService.load();
      if (mounted) setState(() => _kbEntries = entries);
    } catch (_) {}
  }

  Future<void> _loadProfile() async {
    final user = await _auth.currentUser();
    if (mounted && user != null) {
      setState(() {
        _userName = user.name;
        _userEmail = user.email;
      });
    }
  }

  Future<void> _logout() async {
    await _auth.logout();
  }

  @override
  void dispose() {
    _textController.dispose();
    _ttsService.stop();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    await _speechService.initialize();
  }

  void _updateAdvice(String text) {
    if (text.trim().isEmpty) {
      _detectedLabel = '';
      healthAdvice = "I did not hear anything. Please tap and speak again.";
      _speakAdvice();
      return;
    }

    if (_kbEntries.isNotEmpty) {
      final result = NlpService.parse(text, _kbEntries);
      if (result.entry != null) {
        _detectedLabel =
            'Detected: ${result.topic} (${result.condition}) - ${result.intent.name} (${(result.confidence * 100).round()}%)';

        final body = result.entry!.formattedAdvice;
        healthAdvice = result.isEmergency ? 'EMERGENCY:\n$body' : body;
        _logHistory(text, result.topic, result.intent.name);
        _speakAdvice();
        return;
      }
    }

    final topic = HealthService.findForQuery(text);

    if (topic != null) {
      _detectedLabel = 'Detected: ${topic.title} - wellness';
      healthAdvice = '${topic.title}: ${topic.advice}';
      _logHistory(text, topic.title, 'wellness');
    } else {
      _detectedLabel = '';
      healthAdvice =
          "No match found. Try: sleep, water, exercise, diet, stress, malaria, cold, fever or emergency.";
    }
    _speakAdvice();
  }

  Future<void> _speakAdvice() async {
    if (_ttsEnabled) {
      await _ttsService.speak(healthAdvice);
    }
  }

  Future<void> _logHistory(String query, String topic, String intent) async {
    if (kIsWeb) return;
    try {
      final user = await _auth.currentUser();
      final email = user?.email ?? '';
      if (email.isEmpty) return;
      await LocalDbService.instance.addHistory(
        email: email,
        query: query,
        topic: topic,
        intent: intent,
      );
    } catch (_) {}
  }

  void _submitTypedText() {
    final typed = _textController.text;
    setState(() {
      recognizedText = typed.isEmpty ? "No voice input yet" : typed;
      _updateAdvice(typed);
    });
  }

  void listen() async {
    if (!isListening) {
      bool available = await _speechService.initialize();
      if (!available) {
        setState(() {
          recognizedText = "Microphone not available";
          healthAdvice =
              "Please allow microphone permission and check your connection.";
        });
        return;
      }
      setState(() => isListening = true);
      await _speechService.startListening(
        onText: (text) {
          setState(() {
            recognizedText =
                text.isEmpty ? "Listening... please speak" : text;
            _updateAdvice(text);
          });
        },
      );
    } else {
      await _speechService.stop();
      setState(() => isListening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text("VoiceHealth"),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.library_books_outlined),
            tooltip: 'Knowledge sources',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SourcesScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: _logout,
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            children: [

              const SizedBox(height: 8),

              const Text(
                "VoiceHealth Assistant",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 6),

              const Text(
                "Ask health questions by voice or text and get guidance "
                "from the clinical knowledge base.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primary, primary.withValues(alpha: 0.85)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.health_and_safety,
                              color: Colors.white, size: 32),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "VoiceHealth",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Ask health questions by voice or text and get "
                                "guidance from the clinical knowledge base.",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "ACCOUNT",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _userName.isNotEmpty ? _userName : "James Gosling",
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _userEmail.isNotEmpty
                                ? _userEmail
                                : "johndoe@email.com",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfileScreen(
                              settings: AppSettingsService(),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.person_outline, size: 18),
                      label: const Text("Update Profile"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primary,
                        side: BorderSide(color: primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Card(
                elevation: 0,
                color: Colors.grey.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: listen,
                        borderRadius: BorderRadius.circular(40),
                        child: CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.blue.shade50,
                          child: Icon(
                            isListening ? Icons.mic : Icons.mic_none,
                            size: 36,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        "Tap microphone to speak",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: "e.g. How much water should I drink?",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: primary, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        onSubmitted: (_) => _submitTypedText(),
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: _submitTypedText,
                          icon: const Icon(Icons.analytics_outlined,
                              size: 20),
                          label: const Text("Analyze & Recommend",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              )),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Try asking:",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final sample in _samples)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: OutlinedButton(
                          onPressed: () {
                            _textController.text = sample;
                            _submitTypedText();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            side: BorderSide(color: Colors.grey.shade300),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                          ),
                          child: Text(
                            sample,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Recognized Text:",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              child: Text(
                recognizedText,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
            ),

            const SizedBox(height: 25),

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "Health Advice:",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    _ttsEnabled ? Icons.volume_up : Icons.volume_off,
                    color: Colors.blue.shade700,
                  ),
                  tooltip: _ttsEnabled ? 'Turn off voice' : 'Turn on voice',
                  onPressed: () async {
                    setState(() => _ttsEnabled = !_ttsEnabled);
                    await widget.settings.setTtsEnabled(_ttsEnabled);
                    if (_ttsEnabled) {
                      await _ttsService.speak(healthAdvice);
                    } else {
                      await _ttsService.stop();
                    }
                  },
                ),
              ],
            ),

            if (_detectedLabel.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _detectedLabel,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ),

            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                healthAdvice,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ),

            const SizedBox(height: 10),
            Text(
              KnowledgeBaseService.disclaimer,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),
          ],
        ),
        ),
      ),
    );
  }

  // ---- Sample health inquiries
  static const List<String> _samples = [
    'How much water should I drink?',
    'I cannot sleep at night',
    'Fever and chills',
    'Chest pain',
    'What should I eat?',
    'How do I wash my hands?',
  ];
}
