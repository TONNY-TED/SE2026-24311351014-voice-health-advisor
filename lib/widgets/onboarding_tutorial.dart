// Reusable On/Offboarding Tutorial Component
// Can be used for both initial app onboarding and Settings "How to Use the App"
// - Shows 3 slides with manual Next/Back navigation
// - Progress indicator (1/3, 2/3, 3/3)
// - Get Started/Finish on last slide
// - Skip button only in onboarding mode
// - Calls onFinish callback when done

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// TutorialSlide model — holds the data for one slide (image, heading, description).
// The [index] field is 0-based and can be modified after construction.
// ---------------------------------------------------------------------------
class TutorialSlide {
  final String image;
  final String heading;
  final String description;
  int index; // 0-based index — can be updated after construction

  TutorialSlide({
    required this.image,
    required this.heading,
    required this.description,
  }) : index = 0; // default index; will be updated by the tutorial container

  // Convenience constructor that also sets the index.
  factory TutorialSlide.withIndex({
    required String image,
    required String heading,
    required String description,
    required int index,
  }) {
    final sl = TutorialSlide(
      image: image,
      heading: heading,
      description: description,
    );
    sl.index = index;
    return sl;
  }
}

// ---------------------------------------------------------------------------
// Pre-defined slides for VoiceHealth — same slides used in onboarding and Settings.
// ---------------------------------------------------------------------------
extension VoiceHealthSlides on BuildContext {
  static List<TutorialSlide> get voiceHealthSlides => [
    TutorialSlide.withIndex(
      image: 'assets/intro/intro1.png',
      heading: 'Welcome to VoiceHealth',
      description:
          'Your personal healthcare assistant — ask health questions by voice or text and get guidance from the clinical knowledge base.',
      index: 0,
    ),
    TutorialSlide.withIndex(
      image: 'assets/intro/intro2.png',
      heading: 'Get Trusted Advice',
      description:
          'Search our clinical knowledge base for conditions, first aid, nutrition and more. Find answers quickly and reliably.',
      index: 1,
    ),
    TutorialSlide.withIndex(
      image: 'assets/intro/intro3.png',
      heading: 'Book with Confidence',
      description:
          'Find doctors, book appointments, and manage your health — all in one app. View doctor profiles and schedule consultations.',
      index: 2,
    ),
  ];
}

// ---------------------------------------------------------------------------
// OnboardingTutorial — reusable page-based tutorial widget.
// ---------------------------------------------------------------------------
class OnboardingTutorial extends StatefulWidget {
  final List<TutorialSlide> slides;
  final bool showSkip; // show Skip only in onboarding mode
  final VoidCallback? onSkip; // called when Skip tapped (onboarding only)
  final VoidCallback? onNext; // optional — called when Next tapped
  final VoidCallback? onBack; // called when Back tapped (settings mode)
  final VoidCallback onFinish; // called when Finish tapped or Get Started tapped

  const OnboardingTutorial({
    super.key,
    required this.slides,
    this.showSkip = true,
    this.onSkip,
    this.onNext,
    this.onBack,
    required this.onFinish,
  });

  @override
  State<OnboardingTutorial> createState() => _OnboardingTutorialState();
}

class _OnboardingTutorialState extends State<OnboardingTutorial> {
  PageController _pageController = PageController();
  int _currentSlide = 0;
  bool _isOnboarding = true; // true = show Skip, false = show Back

  @override
  void initState() {
    super.initState();
    _currentSlide = widget.slides.first.index;
    _pageController = PageController(initialPage: _currentSlide);
    _pageController.addListener(_onPageChanged);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged() {
    setState(() => _currentSlide = _pageController.page!.round());
  }

  // Move to next slide, or finish if on last slide
  void _nextSlide() {
    if (_currentSlide < widget.slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onFinish();
    }
  }

  // Move to previous slide, or handle Back/Skip logic
  void _previousSlide() {
    if (_currentSlide > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // On first slide of onboarding: show Skip action instead of going back
      if (_isOnboarding && widget.showSkip && widget.onSkip != null) {
        widget.onSkip!();
      } else {
        // In settings mode, go back (or do nothing if no onBack callback)
        if (widget.onBack != null) {
          widget.onBack!();
        }
      }
    }
  }

  bool get _showSkip => _isOnboarding && widget.showSkip && widget.onSkip != null;
  String get _nextButtonText =>
      _currentSlide == widget.slides.length - 1
          ? (_isOnboarding ? 'Get Started' : 'Finish')
          : 'Next';

  // Called when Skip is tapped on the first slide (onboarding mode only)
  void _onSkipPressed() {
    setState(() => _isOnboarding = false);
    widget.onSkip!();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // PageView for slide navigation
          PageView(
            controller: _pageController,
            physics: const ClampingScrollPhysics(),
            children: widget.slides
                .map((slide) => _BuildSlide(slide: slide))
                .toList(),
          ),

          // Progress indicator at top
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '${_currentSlide + 1}/${widget.slides.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Navigation buttons at bottom
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button (settings mode, or first slide of onboarding with Skip)
                  if (!_isOnboarding || _currentSlide > 0)
                    TextButton(
                      onPressed: _previousSlide,
                      child: const Text('Back'),
                    ),
                  // Next/Get Started button
                  ElevatedButton(
                    onPressed: _nextSlide,
                    child: Text(_nextButtonText),
                  ),
                  // Skip button (onboarding mode, first slide only)
                  if (_showSkip)
                    TextButton(
                      onPressed: _onSkipPressed,
                      child: const Text('Skip'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BuildSlide extends StatelessWidget {
  final TutorialSlide slide;

  const _BuildSlide({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF1E3A8A),
      child: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              slide.image,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => const ColoredBox(
                color: Color(0xFF1E3A8A),
              ),
            ),
          ),
          // Dark overlay for text contrast
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.4),
            ),
          ),
          // Content
          Positioned(
            left: 32,
            right: 32,
            bottom: 200,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slide.heading,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  slide.description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}