// Import Flutter Material package
import 'package:flutter/material.dart';

// Import Speech Recognition Module (Week 2: Voice Recognition)
import 'package:healthcare_assistant/services/speech_service.dart';

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
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}

// Home Screen Widget
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// Home Screen State: handles Week 2 voice flow
// Tap Button -> Speak -> Text Appears -> Advice Appears
class _HomeScreenState extends State<HomeScreen> {
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

  @override
  void initState() {
    super.initState();

    // Prepare speech recognition early so tapping the mic is fast.
    _initSpeech();
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

  // Update health advice from recognized text (Week 3/4 placeholder logic).
  void _updateAdvice(String text) {
    // Convert to lower case so "Sleep" and "sleep" both match.
    final lower = text.toLowerCase();

    // Check for known keywords and show matching advice.
    if (lower.contains("sleep")) {
      healthAdvice =
          "Maintain a regular sleep schedule and avoid caffeine before bedtime.";
    } else if (lower.contains("water")) {
      healthAdvice = "Drink at least 8 glasses of water daily.";
    } else if (lower.contains("exercise")) {
      healthAdvice = "Exercise for at least 30 minutes daily.";
    } else if (lower.trim().isEmpty) {
      // Handle empty input: user tapped but said nothing.
      healthAdvice = "I did not hear anything. Please tap and speak again.";
    } else {
      // Fallback when no keyword matches.
      healthAdvice =
          "No recommendation found. Try mentioning sleep, water or exercise.";
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

      // Top App Bar
      appBar: AppBar(
        title: const Text("Healthcare Assistant"),
        centerTitle: true,
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

            const SizedBox(height: 10),

            // Advice Output
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(healthAdvice),
            ),
          ],
        ),
        ),
      ),
    );
  }
}