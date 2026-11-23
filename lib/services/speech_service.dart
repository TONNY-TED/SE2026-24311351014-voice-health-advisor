// Voice Recognition Module for Week 2 / voice-input redesign.
//
// This file wraps the speech_to_text plugin so the rest of the app never
// touches the plugin directly. It owns exactly one recognizer instance and
// forwards partial results, microphone sound levels and lifecycle events to
// a single set of listeners (no duplicate listeners or microphone streams).

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, visibleForTesting;
import 'package:speech_to_text/speech_to_text.dart' as stt;

// Why speech recognition failed (used to show a useful message in the UI).
enum SpeechFailureKind {
  permissionDenied, // microphone blocked / not granted
  unavailable, // recognizer missing or could not start
  noSpeech, // nothing recognised / timeout
  network, // recognizer needs connectivity
  busy, // recognizer already in use
  unknown, // anything else
}

// One speech-recognition failure with a message that is safe to show users.
class SpeechFailure {
  final SpeechFailureKind kind;
  final String message;

  const SpeechFailure(this.kind, this.message);
}

// Simple wrapper around the speech_to_text plugin.
class SpeechService {
  // The actual speech recognizer from the plugin (one per app).
  final stt.SpeechToText _speech = stt.SpeechToText();

  // True after a successful initialize().
  bool _isAvailable = false;

  // True while a listen session is active.
  bool _isListening = false;

  // Guards against two listen() calls racing each other.
  bool _isStarting = false;

  // Live transcript callback. `isFinal` marks the end of an utterance.
  void Function(String text, bool isFinal)? onText;

  // Microphone level, normalised to 0.0 (silence) .. 1.0 (loud).
  void Function(double level)? onSoundLevel;

  // Raw plugin status: 'listening', 'notListening' or 'done'.
  void Function(String status)? onStatus;

  // Recognition failure callback.
  void Function(SpeechFailure failure)? onFailure;

  // Check if speech recognition is ready to use.
  bool get isAvailable => _isAvailable;

  // Check if the microphone is currently listening.
  bool get isListening => _isListening;

  // Initialize speech recognition and ask for microphone permission.
  // Returns true if the device supports speech recognition.
  Future<bool> initialize() async {
    if (_isAvailable) return true;
    try {
      _isAvailable = await _speech.initialize(
        // Called when recognizer status changes (listening / done).
        onStatus: (status) {
          _isListening = status == 'listening';
          onStatus?.call(status);
        },
        // Called when an error happens (blocked mic, no network, etc).
        onError: (error) {
          _isListening = false;
          onFailure?.call(_mapError(error.errorMsg, error.permanent));
        },
        // If the device never sends a final result, the plugin promotes the
        // last partial to final after this timeout (keeps analysis snappy).
        finalTimeout: const Duration(milliseconds: 800),
      );
    } catch (_) {
      _isAvailable = false;
    }
    return _isAvailable;
  }

  // Start listening to the microphone.
  // Callers receive live partial text through onText and volume through
  // onSoundLevel.
  Future<bool> start({String? localeId}) async {
    // Never open a second microphone stream.
    if (_isStarting) return _isListening;
    if (_isListening) return true;

    if (!await initialize()) {
      onFailure?.call(
        const SpeechFailure(
          SpeechFailureKind.permissionDenied,
          'Microphone access is blocked. Allow microphone access in your '
          'phone settings, then tap the microphone to try again.',
        ),
      );
      return false;
    }

    _isStarting = true;
    try {
      await _speech.listen(
        // Receive partial + final results while speaking.
        onResult: (result) =>
            onText?.call(result.recognizedWords.trim(), result.finalResult),
        // Real microphone amplitude from the recognizer, not a simulation.
        onSoundLevelChange: (level) => onSoundLevel?.call(normaliseLevel(level)),
        listenOptions: stt.SpeechListenOptions(
          // Partial results so text appears live while speaking.
          partialResults: true,
          // The app's own voice-activity detection decides when to stop.
          cancelOnError: false,
          // Dictation suits full questions rather than short commands.
          listenMode: stt.ListenMode.dictation,
          // Longer than the app's silence window so our 3-second rule wins;
          // the device may still end the session earlier, which the caller
          // handles by restarting the recognizer.
          pauseFor: const Duration(seconds: 5),
          listenFor: const Duration(seconds: 30),
          localeId: localeId,
        ),
      );
      _isListening = true;
      return true;
    } catch (_) {
      _isListening = false;
      onFailure?.call(
        const SpeechFailure(
          SpeechFailureKind.unavailable,
          'Speech recognition could not start on this device. '
          'Please try again.',
        ),
      );
      return false;
    } finally {
      _isStarting = false;
    }
  }

  // Stop listening. The plugin delivers a final result shortly afterwards.
  Future<void> stop() async {
    // Wait for an in-flight listen() call, otherwise the microphone could
    // stay open while the app believes it has stopped.
    for (int i = 0; i < 20 && _isStarting; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    if (!_isAvailable) return;
    _isListening = false;
    try {
      await _speech.stop();
    } catch (_) {}
  }

  // Cancel without returning a final result.
  Future<void> cancel() async {
    for (int i = 0; i < 20 && _isStarting; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    if (!_isAvailable) return;
    _isListening = false;
    try {
      await _speech.cancel();
    } catch (_) {}
  }

  // Detach listeners so a disposed controller cannot receive callbacks.
  void detach() {
    onText = null;
    onSoundLevel = null;
    onStatus = null;
    onFailure = null;
  }

  // Convert the platform sound level to a 0..1 volume.
  //
  // The plugin reports different scales per platform:
  //  * Android: RMS in dB, roughly -2 (quiet) .. 10 (loud).
  //  * iOS/macOS: dBFS, roughly -55 (quiet) .. 0 (loud).
  @visibleForTesting
  static double normaliseLevel(double raw) {
    if (raw.isNaN || raw.isInfinite) return 0;
    final bool isApple = defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    final double value =
        isApple ? (raw + 55) / 55 : (raw - 1) / 9;
    return value.clamp(0.0, 1.0);
  }

  // Map platform error codes to a user-facing message.
  SpeechFailure _mapError(String message, bool permanent) {
    switch (message) {
      case 'error_permission':
        return const SpeechFailure(
          SpeechFailureKind.permissionDenied,
          'Microphone permission is required. Enable it in your phone '
          'settings, then tap the microphone to retry.',
        );
      case 'error_no_match':
      case 'error_speech_timeout':
        return const SpeechFailure(
          SpeechFailureKind.noSpeech,
          "I didn't catch that. Tap the microphone and speak a little "
          'closer to the phone.',
        );
      case 'error_network':
      case 'error_network_timeout':
        return const SpeechFailure(
          SpeechFailureKind.network,
          'Speech recognition needs an internet connection. Check your '
          'network, then tap the microphone to retry.',
        );
      case 'error_busy':
        return const SpeechFailure(
          SpeechFailureKind.busy,
          'The speech recognizer is busy. Wait a moment, then tap the '
          'microphone to retry.',
        );
      default:
        return SpeechFailure(
          permanent ? SpeechFailureKind.unavailable : SpeechFailureKind.unknown,
          'Speech recognition stopped. Tap the microphone to try again.',
        );
    }
  }
}
