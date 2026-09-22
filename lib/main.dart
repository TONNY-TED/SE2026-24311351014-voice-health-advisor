// Import Flutter Material Design package
import 'package:flutter/material.dart';

// Entry point of the application
void main() {
  runApp(const HealthcareAssistantApp());
}

// Main application widget
class HealthcareAssistantApp extends StatelessWidget {
  const HealthcareAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Removes debug banner from top-right corner
      debugShowCheckedModeBanner: false,

      // Application title
      title: 'Healthcare Assistant',

      // Application theme
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),

      // First screen displayed when app starts
      home: const HomeScreen(),
    );
  }
}

// Home screen widget
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// State class for HomeScreen
class _HomeScreenState extends State<HomeScreen> {

  // Stores text recognized from voice input
  String recognizedText = "No voice input yet";

  // Stores healthcare advice to display
  String healthAdvice = "Your health advice will appear here";

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      // Top navigation bar
      appBar: AppBar(
        title: const Text("Healthcare Assistant"),
        centerTitle: true,
      ),

      // Main screen content
      body: Padding(
        padding: const EdgeInsets.all(20.0),

        child: Column(
          children: [

            // Space from top
            const SizedBox(height: 20),

            // Application heading
            const Text(
              "AI-Powered Healthcare Assistant",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Space below title
            const SizedBox(height: 30),

            // Voice input button
            ElevatedButton.icon(

              // Button click event
              onPressed: () {

                // Update screen content
                setState(() {

                  // Simulated speech recognition result
                  recognizedText =
                      "How can I improve my sleep?";

                  // Simulated AI healthcare recommendation
                  healthAdvice =
                      "Maintain a regular sleep schedule and avoid caffeine before bedtime.";
                });
              },

              // Microphone icon
              icon: const Icon(Icons.mic),

              // Button label
              label: const Text("Tap To Speak"),

              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
              ),
            ),

            // Space below button
            const SizedBox(height: 30),

            // Section title
            Align(
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

            // Container displaying recognized speech
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

            // Health advice heading
            Align(
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

            // Container displaying healthcare recommendation
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
    );
  }
}