// Import Flutter Material package
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

// Import Speech Recognition Module (Week 2: Voice Recognition)
import 'package:healthcare_assistant/services/speech_service.dart';

// Import Authentication Module (register / login / saved profile)
import 'package:healthcare_assistant/services/auth_service.dart';
import 'package:healthcare_assistant/services/health_service.dart';
import 'package:healthcare_assistant/services/knowledge_base_service.dart';
import 'package:healthcare_assistant/services/local_db_service.dart';
import 'package:healthcare_assistant/services/nlp_service.dart';
import 'package:healthcare_assistant/screens/login_screen.dart';

// Application entry point
void main() {
  runApp(const HealthcareAssistantApp());
}

// Main Application Widget
class HealthcareAssistantApp extends StatelessWidget {
  const HealthcareAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Healthcare Assistant',
      // Clean modern theme: blue primary, rounded inputs/cards.
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
      // AuthGate decides: logged in -> HomeScreen, logged out -> LoginScreen.
      home: const AuthGate(),
    );
  }
}

// Auth gate: checks saved session on startup and switches screens.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  // Auth service for session lookup.
  final AuthService _auth = AuthService();

  // Cached login state (null = still loading).
  bool? _loggedIn;

  @override
  void initState() {
    super.initState();
    // Check saved profile once when app opens.
    _checkSession();
  }

  // Look for a saved logged-in user.
  Future<void> _checkSession() async {
    final user = await _auth.currentUser();
    setState(() => _loggedIn = user != null);
  }

  @override
  Widget build(BuildContext context) {
    // Show spinner while reading saved session.
    if (_loggedIn == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Logged in -> main app, else -> login.
    if (_loggedIn!) {
      return HomeScreen(onLoggedOut: () => setState(() => _loggedIn = false));
    }
    return LoginScreen(onLoggedIn: () => setState(() => _loggedIn = true));
  }
}

// Home Screen Widget (main app after login)
class HomeScreen extends StatefulWidget {
  // Called after logout so AuthGate can switch back to login.
  final VoidCallback? onLoggedOut;

  const HomeScreen({super.key, this.onLoggedOut});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// Home Screen State: handles Week 2 voice flow
// Tap Button -> Speak -> Text Appears -> Advice Appears
class _HomeScreenState extends State<HomeScreen> {
  // Auth service for profile display + logout.
  final AuthService _auth = AuthService();

  // Cached profile text shown in the app bar subtitle.
  String _profileLabel = '';

  // Voice recognition module (all mic logic lives in this service).
  final SpeechService _speechService = SpeechService();

  // Indicates whether app is currently listening.
  bool isListening = false;

  // Stores recognized speech to show on screen.
  String recognizedText = "No voice input yet";

  // Stores health advice to show on screen.
  String healthAdvice = "Your health advice will appear here";

  // Controller for typed input (so users can type instead of speaking).
  final TextEditingController _textController = TextEditingController();

  // Full 24-entry VoiceHealth base loaded from assets at startup.
  List<KbEntry> _kbEntries = [];

  // Last NLP parse shown under the advice heading (topic/condition/intent).
  String _detectedLabel = '';

  @override
  void initState() {
    super.initState();

    // Prepare speech recognition early so tapping the mic is fast.
    _initSpeech();

    // Load saved profile to show who is logged in.
    _loadProfile();

    // Load the 24-entry JSON knowledge base in the background.
    _loadKnowledgeBase();
  }

  // Load VoiceHealth JSON once; advice falls back to 6 topics until ready.
  Future<void> _loadKnowledgeBase() async {
    try {
      final entries = await KnowledgeBaseService.load();
      if (mounted) setState(() => _kbEntries = entries);
    } catch (_) {
      // Keep fallback HealthService if asset fails (offline / missing).
    }
  }

  // Load current user profile for the header + welcome text.
  Future<void> _loadProfile() async {
    final user = await _auth.currentUser();
    if (mounted && user != null) {
      setState(() => _profileLabel = '${user.name} (${user.email})');
    }
  }

  // Log out and return to the login screen.
  Future<void> _logout() async {
    await _auth.logout();
    widget.onLoggedOut?.call();
  }

  @override
  void dispose() {
    // Free the text controller when the screen is closed.
    _textController.dispose();
    super.dispose();
  }

  // Initialize the speech engine once when the screen loads.
  Future<void> _initSpeech() async {
    await _speechService.initialize();
  }

  // Update health advice via NLP (Step 5) + recommendation engine.
  // Query -> normalize -> topic/condition/intent -> entry -> guidance.
  // Also stores the query in SQLite history when logged in (phone/desktop).
  void _updateAdvice(String text) {
    // Handle empty input first.
    if (text.trim().isEmpty) {
      _detectedLabel = '';
      healthAdvice = "I did not hear anything. Please tap and speak again.";
      return;
    }

    // 1) NLP parse over the 24-entry base when loaded.
    if (_kbEntries.isNotEmpty) {
      final result = NlpService.parse(text, _kbEntries);
      if (result.entry != null) {
        // Show extracted topic / condition / intent for report + UML.
        _detectedLabel =
            'Detected: ${result.topic} (${result.condition}) - ${result.intent.name} (${(result.confidence * 100).round()}%)';

        // Emergency gets a warning prefix so users act fast.
        final body = result.entry!.formattedAdvice;
        healthAdvice = result.isEmergency ? 'EMERGENCY:\n$body' : body;

        // Save to local history (non-blocking, phone/desktop only).
        _logHistory(text, result.topic, result.intent.name);
        return;
      }
    }

    // 2) Fallback to the 6-topic built-in base (works before JSON loads).
    final topic = HealthService.findForQuery(text);

    if (topic != null) {
      // Show topic title + guidance.
      _detectedLabel = 'Detected: ${topic.title} - wellness';
      healthAdvice = '${topic.title}: ${topic.advice}';
      _logHistory(text, topic.title, 'wellness');
    } else {
      // Fallback lists supported examples.
      _detectedLabel = '';
      healthAdvice =
          "No match found. Try: sleep, water, exercise, diet, stress, malaria, cold, fever or emergency.";
    }
  }

  // Save query to SQLite history for the logged-in user (Step: local data).
  // Skipped on web (sqflite unavailable) and when logged out.
  Future<void> _logHistory(String query, String topic, String intent) async {
    // Chrome web has no SQLite.
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
    } catch (_) {
      // History must never break advice display.
    }
  }

  // Handle typed input: user writes instead of speaking.
  void _submitTypedText() {
    // Read what the user typed.
    final typed = _textController.text;

    setState(() {
      // Show typed text in the same recognized-text box as voice.
      recognizedText = typed.isEmpty ? "No voice input yet" : typed;

      // Reuse the same advice engine as voice input.
      _updateAdvice(typed);
    });
  }

  // Start/Stop Listening Function for the mic button.
  void listen() async {
    // If microphone is not listening, start it.
    if (!isListening) {
      // Ask for permission and check if speech is supported.
      bool available = await _speechService.initialize();

      // Device blocked speech recognition (no mic, no permission, no network).
      if (!available) {
        setState(() {
          recognizedText = "Microphone not available";
          healthAdvice =
              "Please allow microphone permission and check your connection.";
        });
        return;
      }

      // Show listening state in the UI.
      setState(() {
        isListening = true;
      });

      // Start the microphone and update text live as the user speaks.
      await _speechService.startListening(
        onText: (text) {
          setState(() {
            // Store recognized speech, show placeholder if empty.
            recognizedText =
                text.isEmpty ? "Listening... please speak" : text;

            // Generate health advice from the new text.
            _updateAdvice(text);
          });
        },
      );
    }

    // If already listening, stop the microphone.
    else {
      await _speechService.stop();

      setState(() {
        isListening = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      // Top App Bar with saved profile + logout.
      appBar: AppBar(
        title: const Text("Healthcare Assistant"),
        centerTitle: true,
        actions: [
          // Logout button: clears session and shows login screen.
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: _logout,
          ),
        ],
      ),

      // Screen Body (scrollable so keyboard does not overflow)
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            children: [

              const SizedBox(height: 20),

              const Text(
                "AI-Powered Healthcare Assistant",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              // Saved user profile line (from register / login).
              if (_profileLabel.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Logged in as $_profileLabel',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),

              const SizedBox(height: 30),

              // Voice Button
              ElevatedButton.icon(

                onPressed: listen,

                icon: Icon(
                  isListening
                      ? Icons.mic
                      : Icons.mic_none,
                ),

                label: Text(
                  isListening
                      ? "Listening..."
                      : "Tap To Speak",
                ),

                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Typed input label
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Or type your question:",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Text box for typing (alternative to speaking)
              TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: "e.g. How much water should I drink?",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                // Pressing enter on keyboard submits too.
                onSubmitted: (_) => _submitTypedText(),
              ),

              const SizedBox(height: 10),

              // Submit button for typed input
              ElevatedButton.icon(
                onPressed: _submitTypedText,
                icon: const Icon(Icons.send),
                label: const Text("Get Advice"),
              ),

              const SizedBox(height: 12),

              // Quick topic chips from the Knowledge Base (tap to query).
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // One chip per topic; tapping runs it as a query.
                    for (final topic in HealthService.topics)
                      ActionChip(
                        label: Text(topic.title),
                        onPressed: () {
                          // Fill the box + run the same advice engine.
                          _textController.text = topic.title;
                          _submitTypedText();
                        },
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

            // Recognized Text Heading
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Recognized Text:",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Recognized Voice Output
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(recognizedText),
            ),

            const SizedBox(height: 25),

            // Advice Heading
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Health Advice:",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // NLP extraction result (topic / condition / intent + confidence).
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

            // Advice Output (content + tips + see-doctor + source)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(healthAdvice),
            ),

            // Safety disclaimer from the VoiceHealth base.
            const SizedBox(height: 10),
            Text(
              KnowledgeBaseService.disclaimer,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}