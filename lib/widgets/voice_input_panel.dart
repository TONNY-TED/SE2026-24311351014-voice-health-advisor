// Voice input panel: microphone button, live waveform and status labels.
//
// The waveform is driven by the real microphone amplitude reported by the
// recognizer (VoiceInputController.amplitude), not by a random animation.

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../services/voice_input_controller.dart';

// Primary blue used across VoiceHealth.
const Color _primaryBlue = Color(0xFF1976D2);
const Color _lightBlue = Color(0xFFE3F2FD);

class VoiceInputPanel extends StatefulWidget {
  final VoiceInputController controller;

  // Called when the microphone is tapped (start / stop / retry).
  final VoidCallback onMicrophoneTap;

  const VoiceInputPanel({
    super.key,
    required this.controller,
    required this.onMicrophoneTap,
  });

  @override
  State<VoiceInputPanel> createState() => _VoiceInputPanelState();
}

class _VoiceInputPanelState extends State<VoiceInputPanel>
    with TickerProviderStateMixin {
  // Drives the ripple rings + microphone pulse while listening.
  late final AnimationController _ripple = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  // Drives the travelling wave inside the equalizer bars.
  late final AnimationController _phase = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_syncAnimations);
    _syncAnimations();
  }

  @override
  void didUpdateWidget(covariant VoiceInputPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_syncAnimations);
      widget.controller.addListener(_syncAnimations);
      _syncAnimations();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncAnimations);
    _ripple.dispose();
    _phase.dispose();
    super.dispose();
  }

  // Run the animations only while listening to stay battery friendly.
  void _syncAnimations() {
    final bool listening =
        widget.controller.state == VoiceInputState.listening;
    if (listening) {
      if (!_ripple.isAnimating) _ripple.repeat();
      if (!_phase.isAnimating) _phase.repeat();
    } else {
      if (_ripple.isAnimating) {
        _ripple.stop();
        _ripple.value = 0;
      }
      if (_phase.isAnimating) {
        _phase.stop();
        _phase.value = 0;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final VoiceInputController c = widget.controller;
        final bool listening = c.state == VoiceInputState.listening;
        final bool processing = c.state == VoiceInputState.processing;
        final bool failed = c.state == VoiceInputState.error;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: listening ? _primaryBlue.withValues(alpha: 0.35) : _lightBlue,
              width: listening ? 1.6 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: _primaryBlue.withValues(alpha: 0.07),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              _MicrophoneButton(
                listening: listening,
                processing: processing,
                failed: failed,
                ripple: _ripple,
                onTap: widget.onMicrophoneTap,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 56,
                width: double.infinity,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: processing
                      ? Center(
                          key: const ValueKey<String>('progress'),
                          child: SizedBox(
                            width: 150,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                minHeight: 5,
                                backgroundColor: _lightBlue,
                                color: _primaryBlue,
                              ),
                            ),
                          ),
                        )
                      : _Waveform(
                          key: const ValueKey<String>('waveform'),
                          amplitude: c.amplitude,
                          phase: _phase,
                          dimmed: !listening,
                        ),
                ),
              ),
              const SizedBox(height: 10),
              // Announced by screen readers whenever the state changes.
              Semantics(
                liveRegion: true,
                excludeSemantics: true,
                label: c.statusLabel,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Text(
                    c.statusLabel,
                    key: ValueKey<VoiceInputState>(c.state),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: listening
                          ? _primaryBlue
                          : failed
                              ? Theme.of(context).colorScheme.error
                              : Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                c.helperText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  color: failed
                      ? Theme.of(context).colorScheme.error
                      : Colors.grey.shade600,
                ),
              ),
              if (failed) ...[
                const SizedBox(height: 6),
                TextButton.icon(
                  onPressed: widget.onMicrophoneTap,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Try again'),
                  style: TextButton.styleFrom(
                    foregroundColor: _primaryBlue,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ---- Microphone button with pulsing ripple --------------------------------

class _MicrophoneButton extends StatelessWidget {
  final bool listening;
  final bool processing;
  final bool failed;
  final AnimationController ripple;
  final VoidCallback onTap;

  const _MicrophoneButton({
    required this.listening,
    required this.processing,
    required this.failed,
    required this.ripple,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      height: 132,
      child: AnimatedBuilder(
        animation: ripple,
        builder: (context, child) {
          // Subtle breathing pulse while recording.
          final double scale = listening
              ? 1 + 0.045 * math.sin(ripple.value * 2 * math.pi)
              : 1.0;
          return Stack(
            alignment: Alignment.center,
            children: [
              if (listening)
                CustomPaint(
                  size: const Size(132, 132),
                  painter: _RipplePainter(ripple.value, _primaryBlue),
                ),
              Transform.scale(scale: scale, child: child),
            ],
          );
        },
        child: Tooltip(
          message: listening ? 'Stop listening' : 'Start voice input',
          child: Material(
            color: listening ? _primaryBlue : Colors.blue.shade50,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            elevation: listening ? 6 : 1,
            shadowColor: _primaryBlue.withValues(alpha: 0.35),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: processing ? null : onTap,
              child: SizedBox(
                width: 96,
                height: 96,
                child: processing
                    ? const Padding(
                        padding: EdgeInsets.all(30),
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: _primaryBlue,
                        ),
                      )
                    : Icon(
                        failed
                            ? Icons.mic_off
                            : listening
                                ? Icons.mic
                                : Icons.mic_none,
                        size: 42,
                        color: listening ? Colors.white : _primaryBlue,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  final double progress;
  final Color color;

  _RipplePainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double maxRadius = size.shortestSide / 2;
    for (int i = 0; i < 2; i++) {
      final double t = (progress + i * 0.5) % 1.0;
      final double radius = maxRadius * (0.62 + 0.30 * t);
      final Paint paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color.withValues(alpha: 0.30 * (1 - t));
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

// ---- Live waveform --------------------------------------------------------

class _Waveform extends StatelessWidget {
  final double amplitude;
  final Animation<double> phase;
  final bool dimmed;

  const _Waveform({
    super.key,
    required this.amplitude,
    required this.phase,
    required this.dimmed,
  });

  @override
  Widget build(BuildContext context) {
    // Smooth the raw microphone level so bars glide instead of jumping.
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: amplitude),
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      builder: (context, eased, _) {
        return AnimatedBuilder(
          animation: phase,
          builder: (context, child) {
            return CustomPaint(
              size: const Size(double.infinity, 56),
              painter: _WaveformPainter(
                amplitude: eased,
                phase: phase.value,
                dimmed: dimmed,
              ),
            );
          },
        );
      },
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double amplitude;
  final double phase;
  final bool dimmed;

  _WaveformPainter({
    required this.amplitude,
    required this.phase,
    required this.dimmed,
  });

  static const int _barCount = 25;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final double gap = size.width * 0.010;
    final double barWidth =
        (size.width - gap * (_barCount - 1)) / _barCount;
    final double centerY = size.height / 2;
    final double minHeight = 3;
    final double maxHeight = size.height;

    final Paint paint = Paint()..strokeCap = StrokeCap.round;

    for (int i = 0; i < _barCount; i++) {
      final double t = i / (_barCount - 1);
      // Taller in the middle so the wave keeps a pleasing shape.
      final double envelope = 0.45 + 0.55 * math.sin(math.pi * t);
      // Travelling ripple makes the bars move with the same input level.
      final double osc =
          0.65 + 0.35 * math.sin(2 * math.pi * (phase + i * 0.09));
      final double level = (amplitude * envelope * osc).clamp(0.0, 1.0);
      final double height = minHeight + (maxHeight - minHeight) * level;
      final double x = i * (barWidth + gap);

      final Color color = Color.lerp(
        const Color(0xFF90CAF9),
        _primaryBlue,
        level,
      )!;

      paint.color = dimmed ? color.withValues(alpha: 0.30) : color;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, centerY - height / 2, barWidth, height),
          Radius.circular(barWidth / 2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) =>
      oldDelegate.amplitude != amplitude ||
      oldDelegate.phase != phase ||
      oldDelegate.dimmed != dimmed;
}
