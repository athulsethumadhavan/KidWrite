import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Core/Constants/app_colors.dart';
import '../../Core/Constants/app_constants.dart';
import '../../Core/widgets/animated_background.dart';

/// First-run introduction: what the app teaches, how tracing works, how
/// stars are earned, and where the (grown-up) settings live.
class OnboardingPage extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingPage({super.key, required this.onDone});

  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(AppConstants.prefOnboardingDone) ?? false);
  }

  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefOnboardingDone, true);
  }

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  static const _pages = <_OnboardStep>[
    _OnboardStep(
      emoji: '✏️',
      title: 'Welcome to KidWrite!',
      body:
          'A fun way for little ones to learn writing — starting with '
          'lines and shapes, then numbers and letters in four languages.',
      color: AppColors.primary,
    ),
    _OnboardStep(
      emoji: '👆',
      title: 'Follow the hand',
      body:
          'A friendly hand shows exactly how each stroke is drawn. Your '
          'child traces along the dotted line with a finger.',
      color: AppColors.secondary,
    ),
    _OnboardStep(
      emoji: '⭐️',
      title: 'Earn three stars',
      body:
          'Trace it twice with the guide, then once from memory. Three '
          'stars unlock the next letter on the map!',
      color: Color(0xFFFFB300),
    ),
    _OnboardStep(
      emoji: '🔒',
      title: 'Grown-ups only',
      body:
          'Settings — ratings, help and privacy — are behind a LONG PRESS '
          'on the gear icon, so little fingers can\'t wander off.',
      color: AppColors.purple,
    ),
  ];

  Future<void> _finish() async {
    await OnboardingPage.markSeen();
    widget.onDone();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _pages.length - 1;
    return Scaffold(
      body: AnimatedBackground(
        primaryColor: _pages[_index].color,
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _finish,
                  child: const Text(
                    'Skip',
                    style: TextStyle(color: AppColors.textLight),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) {
                    final p = _pages[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  color: p.color.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    p.emoji,
                                    style: const TextStyle(fontSize: 76),
                                  ),
                                ),
                              )
                              .animate(key: ValueKey(i))
                              .scale(duration: 500.ms, curve: Curves.elasticOut)
                              .fadeIn(duration: 300.ms),
                          const SizedBox(height: 36),
                          Text(
                            p.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            p.body,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < _pages.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _index ? 26 : 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: i == _index
                            ? _pages[_index].color
                            : AppColors.textLight.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 26),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 28),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _pages[_index].color,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: () {
                      if (isLast) {
                        _finish();
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutCubic,
                        );
                      }
                    },
                    child: Text(
                      isLast ? "Let's write! ✏️" : 'Next',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardStep {
  final String emoji;
  final String title;
  final String body;
  final Color color;
  const _OnboardStep({
    required this.emoji,
    required this.title,
    required this.body,
    required this.color,
  });
}
