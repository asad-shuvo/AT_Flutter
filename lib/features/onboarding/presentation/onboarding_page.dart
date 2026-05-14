import 'dart:async';

import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/app/router/app_router.dart';
import 'package:flutter/material.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  Timer? _progressTimer;

  int _currentIndex = 0;
  double _currentProgress = 0;

  bool get _isLastSlide =>
      _currentIndex == _slidesFor(AppLocalizations.of(context)).length - 1;

  static const Duration _tickDuration = Duration(milliseconds: 100);
  static const double _progressStep = 0.02;

  @override
  void initState() {
    super.initState();
    _startProgressTimer();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _goToLogin() {
    _progressTimer?.cancel();
    Navigator.of(context).pushReplacementNamed(AppRouter.login);
  }

  Future<void> _handlePrimaryAction() async {
    _progressTimer?.cancel();

    if (_isLastSlide) {
      _goToLogin();
      return;
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(_tickDuration, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final nextProgress = (_currentProgress + _progressStep).clamp(0.0, 1.0);

      if (nextProgress >= 1) {
        timer.cancel();
        _advanceFromTimer();
        return;
      }

      setState(() {
        _currentProgress = nextProgress;
      });
    });
  }

  Future<void> _advanceFromTimer() async {
    if (_isLastSlide) {
      _goToLogin();
      return;
    }

    setState(() {
      _currentProgress = 0;
    });

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  List<_OnboardingSlide> _slidesFor(AppLocalizations l10n) {
    return <_OnboardingSlide>[
      _OnboardingSlide(
        backgroundAsset: 'assets/images/onboarding/wave1.png',
        contentAsset: 'assets/images/onboarding/managecontracts.png',
        title: l10n.tr('tns.title'),
        description: l10n.tr('tns.description'),
      ),
      _OnboardingSlide(
        backgroundAsset: 'assets/images/onboarding/wave2.png',
        contentAsset: 'assets/images/onboarding/real_estate.png',
        title: l10n.tr('tns.title'),
        description: l10n.tr('tns.description'),
      ),
      _OnboardingSlide(
        backgroundAsset: 'assets/images/onboarding/wave3.png',
        contentAsset: 'assets/images/onboarding/drive.png',
        title: l10n.tr('tns.title'),
        description: l10n.tr('tns.description'),
      ),
      _OnboardingSlide(
        backgroundAsset: 'assets/images/onboarding/wave4.png',
        contentAsset: 'assets/images/onboarding/chatwithadvisor.png',
        title: l10n.tr('tns.title'),
        description: l10n.tr('tns.description'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final slides = _slidesFor(l10n);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(
                children: List<Widget>.generate(
                  slides.length,
                  (index) => Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(
                        right: index == slides.length - 1 ? 0 : 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6E6E6),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: index < _currentIndex
                            ? 1
                            : index == _currentIndex
                            ? _currentProgress
                            : 0,
                        child: Container(color: const Color(0xFFD91F32)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                    _currentProgress = 0;
                  });
                  _startProgressTimer();
                },
                itemCount: slides.length,
                itemBuilder: (context, index) {
                  final slide = slides[index];
                  return _OnboardingSlideView(
                    slide: slide,
                    theme: theme,
                    onTap: _handlePrimaryAction,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _handlePrimaryAction,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFD91F32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _isLastSlide
                        ? l10n.tr('tns.startNow')
                        : l10n.tr('tns.skip'),
                    style: const TextStyle(
                      fontFamily: 'Calibri',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlideView extends StatelessWidget {
  const _OnboardingSlideView({
    required this.slide,
    required this.theme,
    required this.onTap,
  });

  final _OnboardingSlide slide;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          slide.backgroundAsset,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
          child: GestureDetector(
            onTap: onTap,
            child: Center(
              child: Container(
                width: 320,
                constraints: const BoxConstraints(
                  maxWidth: 360,
                  maxHeight: 560,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: Image.asset(
                          slide.contentAsset,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      slide.title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontFamily: 'Calibri',
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w400,
                        fontSize: 28,
                        color: const Color(0xFF5A5551),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      slide.description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Calibri',
                        fontSize: 16,
                        height: 1.35,
                        color: Color(0xFF6A6A6A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.backgroundAsset,
    required this.contentAsset,
    required this.title,
    required this.description,
  });

  final String backgroundAsset;
  final String contentAsset;
  final String title;
  final String description;
}
