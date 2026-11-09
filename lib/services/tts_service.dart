// Text-to-Speech Module
// Reads out health advice results when the user has enabled TTS in Settings.
// Optional — disabled by default so results are never spoken without consent.

import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();

  bool _isInitialized = false;
  bool _enabled = false;

  bool get enabled => _enabled;

  // Set whether TTS is active. Persisted by AppSettingsService.
  void setEnabled(bool value) {
    _enabled = value;
  }

  // Initialize TTS once (language, pitch, speech rate).
  Future<void> initialize() async {
    if (_isInitialized) return;
    await _tts.setLanguage("en-US");
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.5);
    _isInitialized = true;
  }

  // Speak the given text if TTS is enabled.
  Future<void> speak(String text) async {
    if (!_enabled || text.trim().isEmpty) return;
    if (!_isInitialized) await initialize();
    await _tts.speak(text);
  }

  // Stop any ongoing speech.
  Future<void> stop() async {
    await _tts.stop();
  }
}
