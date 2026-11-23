// Voice input state machine for the home screen.
//
// Responsibilities:
//  * start / stop the microphone exactly once per session,
//  * turn live microphone levels into a waveform amplitude,
//  * detect ~3 seconds of silence and finalise the utterance automatically,
//  * keep the recognizer alive across the device's own short timeouts,
//  * only hand a *final* transcript to the health-query pipeline.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart'
    show AppLifecycleState, WidgetsBinding, WidgetsBindingObserver;

import 'speech_service.dart';

// The four visible states from the design brief (+ error).
enum VoiceInputState {
  idle, // microphone inactive
  listening, // microphone active, waveform live
  processing, // silence detected, query being analysed
  result, // advice displayed
  error, // permission / recognition / empty-speech failure
}

class VoiceInputController extends ChangeNotifier with WidgetsBindingObserver {
  VoiceInputController({
    required this.onFinalized,
    SpeechService? speechService,
    this.silenceTimeout = const Duration(seconds: 3),
    this.maxUtterance = const Duration(seconds: 60),
    this.voiceThreshold = 0.15,
    this.localeId,
  }) : _speech = speechService ?? SpeechService() {
    // One recognizer, one set of listeners.
    _speech.onText = _handleText;
    _speech.onSoundLevel = _handleSoundLevel;
    _speech.onStatus = _handleStatus;
    _speech.onFailure = _handleFailure;
    WidgetsBinding.instance.addObserver(this);
  }

  // Called once, with the final transcript, after silence is detected.
  final FutureOr<void> Function(String transcript) onFinalized;

  // Silence needed before the utterance is finalised (configurable).
  final Duration silenceTimeout;

  // Hard cap so a noisy room cannot record forever.
  final Duration maxUtterance;

  // Normalised level (0..1) above which we treat input as speech.
  final double voiceThreshold;

  // Optional speech-recognition locale (null = device language).
  final String? localeId;

  final SpeechService _speech;

  VoiceInputState _state = VoiceInputState.idle;
  String _transcript = '';
  String _committed = '';
  String _partial = '';
  String _errorMessage = '';
  double _amplitude = 0;

  Timer? _silenceTicker;
  Timer? _limitTimer;
  Completer<void>? _finalSignal;

  DateTime _lastVoiceAt = DateTime.now();
  DateTime _lastTextAt = DateTime.now();
  DateTime _sessionStart = DateTime.now();

  bool _finalizing = false;
  bool _restarting = false;
  bool _starting = false;
  bool _gotFinal = false;
  int _restartCount = 0;
  bool _disposed = false;

  // Learned ambient noise level, so a noisy room does not look like speech.
  double _noiseFloor = 0.04;

  // Level (0..1) above which sound counts as speech rather than background.
  double get _speechCutoff {
    final double adaptive = _noiseFloor + 0.16;
    return adaptive.clamp(voiceThreshold, 0.55);
  }

  // ---- Public state -------------------------------------------------------

  VoiceInputState get state => _state;

  bool get isListening => _state == VoiceInputState.listening;

  bool get isProcessing => _state == VoiceInputState.processing;

  // True while the recognizer is starting (permission dialog, mic open).
  bool get isStarting => _starting;

  // Live transcript (committed text + current partial), for the text field.
  String get transcript => _transcript;

  // 0.0 .. 1.0 microphone amplitude for the waveform.
  double get amplitude => _amplitude;

  String get errorMessage => _errorMessage;

  String get statusLabel {
    switch (_state) {
      case VoiceInputState.idle:
        return 'Tap microphone to speak';
      case VoiceInputState.listening:
        return 'Listening... Speak now';
      case VoiceInputState.processing:
        return 'Analyzing your symptoms...';
      case VoiceInputState.result:
        return 'Guidance ready';
      case VoiceInputState.error:
        return 'Voice input stopped';
    }
  }

  String get helperText {
    switch (_state) {
      case VoiceInputState.idle:
        return 'Speak naturally — recording stops ${silenceTimeout.inSeconds} '
            'seconds after you finish.';
      case VoiceInputState.listening:
        return 'Pause for ${silenceTimeout.inSeconds}s and I will finish '
            'automatically. Tap the microphone to stop now.';
      case VoiceInputState.processing:
        return 'Checking the clinical knowledge base. Please wait.';
      case VoiceInputState.result:
        return 'Tap the microphone to ask another question.';
      case VoiceInputState.error:
        return _errorMessage;
    }
  }

  // ---- Session control ----------------------------------------------------

  // Begin listening (requests microphone permission on first use).
  Future<void> start() async {
    if (_state == VoiceInputState.listening || _state == VoiceInputState.processing) {
      return;
    }
    _resetSession();
    _state = VoiceInputState.listening;
    _starting = true;
    notifyListeners();

    final bool started = await _speech.start(localeId: localeId);
    _starting = false;
    if (!started) {
      // onFailure already set a message; make sure we do not stay "listening".
      _stopTimers();
      _amplitude = 0;
      if (_state == VoiceInputState.listening) {
        _setError(
          'Microphone is not available. Check your permission and connection, '
          'then tap to retry.',
        );
      }
      return;
    }

    // The session may have been cancelled while the microphone was opening
    // (permission dialog, typing, leaving the screen).
    if (_state != VoiceInputState.listening || _disposed) {
      await _speech.cancel();
      return;
    }

    _sessionStart = DateTime.now();
    _lastVoiceAt = _sessionStart;
    _lastTextAt = _sessionStart;
    _startTimers();
    notifyListeners();
  }

  // Stop listening immediately and finalise what was said.
  Future<void> stopAndFinalize() => _finalize();

  // Abandon the current session (used when leaving the screen / typing).
  Future<void> cancel() async {
    _stopTimers();
    _finalizing = false;
    _restarting = false;
    _amplitude = 0;
    _partial = '';
    _committed = '';
    _transcript = '';
    if (_state == VoiceInputState.listening) {
      _state = VoiceInputState.idle;
    }
    notifyListeners();
    await _speech.cancel();
  }

  // Return to the resting state after a result, keeping the transcript.
  void reset() {
    if (_state == VoiceInputState.processing) return;
    _stopTimers();
    _finalizing = false;
    _restarting = false;
    _amplitude = 0;
    _partial = '';
    _errorMessage = '';
    _state = VoiceInputState.idle;
    notifyListeners();
  }

  // ---- Speech callbacks ---------------------------------------------------

  void _handleSoundLevel(double level) {
    if (_state != VoiceInputState.listening) return;
    _amplitude = level;
    final double cutoff = _speechCutoff;
    // Real voice activity resets the 3-second silence countdown.
    if (level >= cutoff) {
      _lastVoiceAt = DateTime.now();
    } else {
      // Learn the room's background level while nobody is speaking.
      _noiseFloor = (_noiseFloor * 0.95 + level * 0.05).clamp(0.0, 0.5);
    }
    notifyListeners();
  }

  void _handleText(String text, bool isFinal) {
    if (_state != VoiceInputState.listening && !_finalizing) return;

    if (isFinal) {
      _gotFinal = true;
      _commit(text);
      _partial = '';
      _lastTextAt = DateTime.now();
      final signal = _finalSignal;
      if (signal != null && !signal.isCompleted) signal.complete();
    } else {
      if (text.isEmpty) return;
      // Only reset the silence clock when the words actually change.
      if (text != _partial) {
        _lastVoiceAt = DateTime.now();
        _lastTextAt = _lastVoiceAt;
      }
      _partial = text;
    }

    _refreshTranscript();
    notifyListeners();
  }

  void _handleStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      if (_state == VoiceInputState.listening && !_finalizing) {
        _onRecognitionStopped();
      }
    }
  }

  void _handleFailure(SpeechFailure failure) {
    // Errors that arrive while we are already finalising are expected.
    if (_finalizing) return;
    if (_state != VoiceInputState.listening) return;

    // Some errors mean "the user finished talking" rather than a real fault.
    if (failure.kind == SpeechFailureKind.noSpeech &&
        _transcript.trim().isNotEmpty) {
      _finalize();
      return;
    }

    _stopTimers();
    _finalizing = false;
    _restarting = false;
    _amplitude = 0;
    _setError(failure.message);
  }

  // ---- Silence detection --------------------------------------------------

  void _startTimers() {
    _stopTimers();
    // 100 ms resolution is plenty for a 3-second window and stays cheap.
    _silenceTicker =
        Timer.periodic(const Duration(milliseconds: 100), (_) => _checkSilence());
    _limitTimer = Timer(maxUtterance, () {
      if (_state == VoiceInputState.listening) _finalize();
    });
  }

  void _stopTimers() {
    _silenceTicker?.cancel();
    _silenceTicker = null;
    _limitTimer?.cancel();
    _limitTimer = null;
  }

  void _checkSilence() {
    if (_state != VoiceInputState.listening || _finalizing) return;
    final DateTime now = DateTime.now();
    if (now.difference(_lastVoiceAt) >= silenceTimeout) {
      _finalize();
      return;
    }
    // Safety net for very noisy rooms where the microphone level never drops:
    // stop once no new words have been recognised for a longer window.
    if (_transcript.trim().isNotEmpty &&
        now.difference(_lastTextAt) >= silenceTimeout * 2) {
      _finalize();
    }
  }

  // The device recognizer may stop after its own short timeout. If the user
  // simply paused, restart it so the 3-second rule can still apply.
  Future<void> _onRecognitionStopped() async {
    if (_state != VoiceInputState.listening || _finalizing) return;
    if (DateTime.now().difference(_lastVoiceAt) >= silenceTimeout) {
      await _finalize();
      return;
    }

    // A device-ended session does not always deliver a final result. Keep the
    // words it already showed so they are not lost when we restart.
    if (_partial.isNotEmpty) {
      _commit(_partial);
      _partial = '';
      _refreshTranscript();
      _lastTextAt = DateTime.now();
      notifyListeners();
    }

    await _restartRecognition();
  }

  Future<void> _restartRecognition() async {
    if (_state != VoiceInputState.listening ||
        _finalizing ||
        _restarting ||
        _starting) {
      return;
    }
    _restarting = true;
    _restartCount++;
    // Safety valve: never loop forever.
    if (_restartCount > 60 ||
        DateTime.now().difference(_sessionStart) >= maxUtterance) {
      _restarting = false;
      await _finalize();
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (_state == VoiceInputState.listening && !_finalizing) {
      _gotFinal = false;
      final bool ok = await _speech.start(localeId: localeId);
      if (!ok) {
        _restarting = false;
        await _finalize();
        return;
      }
    }
    _restarting = false;
  }

  // ---- Finalisation -------------------------------------------------------

  Future<void> _finalize() async {
    if (_finalizing || _state != VoiceInputState.listening) return;
    _finalizing = true;
    _stopTimers();

    final String beforeStop = _transcript.trim();
    _amplitude = 0;
    _state = VoiceInputState.processing;
    notifyListeners();

    // Microphone off before any analysis begins.
    final bool wasListening = _speech.isListening;
    final bool alreadyFinal = _gotFinal;
    _finalSignal = Completer<void>();
    await _speech.stop();

    if (wasListening && !alreadyFinal) {
      // The plugin promotes the last partial to final after its own timeout.
      try {
        await _finalSignal!.future.timeout(const Duration(milliseconds: 1200));
      } catch (_) {
        // Timed out: fall back to the best transcript we have.
      }
    }
    _finalSignal = null;
    if (_disposed) return;

    final String transcript =
        _transcript.trim().isEmpty ? beforeStop : _transcript.trim();

    if (transcript.isEmpty) {
      _finalizing = false;
      _setError(
        "I didn't hear anything. Tap the microphone and speak again.",
      );
      return;
    }

    final DateTime startedAt = DateTime.now();
    try {
      await onFinalized(transcript);
      // Keep the processing state visible long enough to read.
      final Duration elapsed = DateTime.now().difference(startedAt);
      const Duration minimum = Duration(milliseconds: 600);
      if (elapsed < minimum) {
        await Future<void>.delayed(minimum - elapsed);
      }
      if (_disposed) return;
      _finalizing = false;
      _state = VoiceInputState.result;
      notifyListeners();
    } catch (_) {
      if (_disposed) return;
      _finalizing = false;
      _setError(
        'Something went wrong while analysing your query. Please try again.',
      );
    }
  }

  // ---- Helpers ------------------------------------------------------------

  void _commit(String text) {
    final String clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.isEmpty) return;
    if (_committed.isEmpty) {
      _committed = clean;
      return;
    }
    final String current = _committed.toLowerCase();
    final String incoming = clean.toLowerCase();
    if (incoming == current) {
      // Exact repeat: nothing new to add.
      return;
    }
    if (incoming.startsWith(current)) {
      // Device re-sent the whole phrase from the start of the session.
      _committed = clean;
      return;
    }
    if (current.startsWith(incoming) || current.endsWith(incoming)) {
      // Prefix / suffix of what we already have: re-recognised text.
      return;
    }
    // New phrase from a restarted recognizer session.
    _committed = '$_committed $clean';
  }

  void _refreshTranscript() {
    _transcript = [
      if (_committed.isNotEmpty) _committed,
      if (_partial.isNotEmpty) _partial,
    ].join(' ').trim();
  }

  void _resetSession() {
    _stopTimers();
    _committed = '';
    _partial = '';
    _transcript = '';
    _errorMessage = '';
    _amplitude = 0;
    _finalizing = false;
    _restarting = false;
    _gotFinal = false;
    _restartCount = 0;
    _finalSignal = null;
    _noiseFloor = 0.04;
    _sessionStart = DateTime.now();
    _lastVoiceAt = _sessionStart;
    _lastTextAt = _sessionStart;
  }

  void _setError(String message) {
    if (_disposed) return;
    _stopTimers();
    _amplitude = 0;
    _errorMessage = message;
    _state = VoiceInputState.error;
    notifyListeners();
    // Make sure the microphone is released after a failure.
    unawaited(_speech.cancel());
  }

  // Guard against callbacks arriving after the widget is torn down.
  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  // Stop recording when the app leaves the foreground.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Ignore the permission dialog / transient inactive state while starting.
    if (_starting) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      if (_state == VoiceInputState.listening) {
        cancel();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _stopTimers();
    _speech.detach();
    _speech.cancel();
    super.dispose();
  }
}
