// Text-to-Speech Module
// Reads out health advice results when the user has enabled TTS in Settings.
// Optional — disabled by default so results are never spoken without consent.

import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();

  bool _isInitialized = false;
  bool _enabled = false;
  String _language = 'en-US';

  bool get enabled => _enabled;

  // Current TTS language, e.g. "en-US" or Chichewa "ny-NG".
  String get language => _language;

  // Set whether TTS is active. Persisted by AppSettingsService.
  void setEnabled(bool value) {
    _enabled = value;
  }

  // Set the language the advice is spoken in, e.g. "en-US" or "ny-NG".
  // Used when the matched knowledge-base entry is in another language.
  Future<void> setLanguage(String language) async {
    _language = language;
    if (!_isInitialized) return;
    await _tts.setLanguage(language);
  }

  // Initialize TTS once (language, pitch, speech rate).
  Future<void> initialize() async {
    if (_isInitialized) return;
    await _tts.setLanguage(_language);
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
