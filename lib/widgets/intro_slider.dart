// Intro Slider: full-screen onboarding shown once before the login page.
// Auto-advances every 2 seconds, then navigates to login.
// Persists "shown" status via AppSettingsService so it never repeats.

import 'package:flutter/material.dart';
import '../services/app_settings_service.dart';

class IntroSlider extends StatefulWidget {
  final AppSettingsService settings;
  final VoidCallback onFinish;

  const IntroSlider({
    super.key,
    required this.settings,
    required this.onFinish,
  });

  @override
  State<IntroSlider> createState() => _IntroSliderState();
}

class _IntroSliderState extends State<IntroSlider> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Each slide: image asset, heading, body text.
  static const List<Map<String, String>> _slides = [
    {
      'image': 'assets/intro/intro1.png',
      'heading': 'Welcome to VoiceHealth',
      'body': 'Your personal healthcare assistant — ask health questions by voice or text.',
    },
    {
      'image': 'assets/intro/intro2.png',
      'heading': 'Get Trusted Advice',
      'body': 'Search our clinical knowledge base for conditions, first aid, nutrition and more.',
    },
    {
      'image': 'assets/intro/intro3.png',
      'heading': 'Book with Confidence',
      'body': 'Find doctors, book appointments, and manage your health — all in one app.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoAdvance();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoAdvance() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return false;
      if (_currentPage < _slides.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        return true;
      }
      // Last slide reached — mark intro as shown and go to login.
      await widget.settings.setIntroShown(true);
      widget.onFinish();
      return false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        itemCount: _slides.length,
        onPageChanged: (index) => setState(() => _currentPage = index),
        itemBuilder: (context, index) {
          final slide = _slides[index];
          return _Slide(
            image: slide['image']!,
            heading: slide['heading']!,
            body: slide['body']!,
            isLast: index == _slides.length - 1,
            currentPage: _currentPage,
            totalSlides: _slides.length,
          );
        },
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final String image;
  final String heading;
  final String body;
  final bool isLast;
  final int currentPage;
  final int totalSlides;

  const _Slide({
    required this.image,
    required this.heading,
    required this.body,
    required this.isLast,
    required this.currentPage,
    required this.totalSlides,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF1E3A8A), // deep blue fallback if image missing
      child: Stack(
        children: [
          // Full-screen background image.
          Positioned.fill(
            child: Image.asset(
              image,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => const ColoredBox(
                color: Color(0xFF1E3A8A),
              ),
            ),
          ),
          // Subtle dark overlay for text contrast.
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.35),
            ),
          ),
          // Content overlay.
          Positioned(
            left: 32,
            right: 32,
            bottom: isLast ? 96 : 160,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  heading,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  body,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          // Page indicator dots.
          if (!isLast)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  totalSlides,
                  (i) => Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: i == currentPage
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
