// Welcome Loading Screen: shown after the intro slides, before the login screen.
// Uses the same background as the login screen (assets/bg.png + dark blue overlay).
// Cool animation: fade + scale entrance, pulsing logo glow, spinner.

import 'package:flutter/material.dart';

class WelcomeLoadingScreen extends StatefulWidget {
  const WelcomeLoadingScreen({super.key});

  @override
  State<WelcomeLoadingScreen> createState() => _WelcomeLoadingScreenState();
}

class _WelcomeLoadingScreenState extends State<WelcomeLoadingScreen>
    with TickerProviderStateMixin {
  // Entrance animation (fade + scale into view).
  static const Duration _entranceDuration = Duration(milliseconds: 900);
  late final AnimationController _entranceCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  // Continuous pulse for the logo glow.
  static const Duration _pulseDuration = Duration(milliseconds: 1100);
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: _entranceDuration,
    );
    _fadeAnim = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutBack));
    _pulseCtrl = AnimationController(vsync: this, duration: _pulseDuration);
    _entranceCtrl.forward();
    _pulseCtrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _pulseCtrl.stop();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Same background as the login screen (fallback + overlay included).
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 0, 55, 175),
          image: DecorationImage(
            image: AssetImage('assets/bg.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Color(0x4D002266),
              BlendMode.darken,
            ),
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([_entranceCtrl, _pulseCtrl]),
            builder: (context, _) => FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (context, _) => Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(
                                alpha: 0.3 + 0.35 * _pulseCtrl.value,
                              ),
                              blurRadius: 24 + 20 * _pulseCtrl.value,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.health_and_safety,
                          size: 52,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 4,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Preparing your health assistant...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
