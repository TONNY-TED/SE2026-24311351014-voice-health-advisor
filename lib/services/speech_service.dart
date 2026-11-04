// Voice Recognition Module for Week 2
// This file handles all microphone / speech-to-text work
// so that main.dart only deals with UI.

import 'package:speech_to_text/speech_to_text.dart' as stt;

// Simple wrapper around the speech_to_text plugin.
class SpeechService {
  // The actual speech recognizer from the plugin.
  final stt.SpeechToText _speech = stt.SpeechToText();

  // True after successful initialize().
  bool _isAvailable = false;

  // Check if speech recognition is ready to use.
  bool get isAvailable => _isAvailable;

  // Check if the microphone is currently listening.
  bool get isListening => _speech.isListening;

  // Initialize speech recognition and ask for microphone permission.
  // Returns true if the device supports speech recognition.
  Future<bool> initialize() async {
    // initialize() prompts for permission on first run.
    _isAvailable = await _speech.initialize(
      // Called when recognizer status changes (listening / done).
      onStatus: (status) {},
      // Called when an error happens (blocked mic, no network, etc).
      onError: (error) {},
    );
    return _isAvailable;
  }

  // Start listening to the microphone.
  // onText is called every time new words are recognized.
  Future<void> startListening({
    required void Function(String text) onText,
  }) async {
    // Make sure initialize() was called first.
    if (!_isAvailable) {
      final ok = await initialize();
      if (!ok) return;
    }

    // Start the microphone listener.
    await _speech.listen(
      // Receive partial + final results while speaking.
      onResult: (result) {
        // Send recognized words back to the UI.
        onText(result.recognizedWords);
      },
      // How long to listen before auto-stop (60 sec is plugin max).
      listenFor: const Duration(seconds: 60),
      // Stop after 5 sec of silence.
      pauseFor: const Duration(seconds: 5),
      // Use partial results so text appears live while speaking.
      partialResults: true,
    );
  }

  // Stop listening to the microphone.
  Future<void> stop() async {
    await _speech.stop();
  }

  // Cancel without returning a final result.
  Future<void> cancel() async {
    await _speech.cancel();
  }
}