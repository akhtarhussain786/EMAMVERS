import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../widgets/design_system_widgets.dart';

class OnboardingView extends StatefulWidget {
  final VoidCallback onComplete;
  final void Function(bool isSignUp, String defaultRole)? onNavigateAuth;

  const OnboardingView({
    super.key,
    required this.onComplete,
    this.onNavigateAuth,
  });

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<OnboardingSlideData> _slides = [
    const OnboardingSlideData(
      title: 'Real NTA & TCS Pattern\nExam Simulations',
      subtitle: 'Experience authentic test interfaces with live timers, negative marking, instant answers, and percentile ranking.',
      icon: Icons.speed_rounded,
      badgeText: 'PRECISION TEST ENGINE',
      accentColor: AppConstants.accentCyan,
      gradient: LinearGradient(
        colors: [Color(0xFF1D4ED8), Color(0xFF0284C7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      tags: ['⚡ Live Timed Tests', '📊 AIR Percentile', '🌐 Hindi & English'],
    ),
    const OnboardingSlideData(
      title: 'AI Diagnostic Coach &\nMistake Notebook',
      subtitle: 'Your 24/7 AI preparation twin. Analyzes recurring mistakes, pinpoints weak chapters, and predicts your cutoff clearance.',
      icon: Icons.auto_awesome_rounded,
      badgeText: 'AI TWIN & MENTOR',
      accentColor: AppConstants.accentPurple,
      gradient: LinearGradient(
        colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      tags: ['🧠 1-on-1 AI Coach', '📓 Auto Mistake Book', '🎯 Smart Revision'],
    ),
    const OnboardingSlideData(
      title: 'Interactive Map Learning\n& All-India Ranks',
      subtitle: 'Master GS, Geography, and Current Affairs on high-res interactive maps. Earn daily XP, badges, and top leaderboard ranks.',
      icon: Icons.public_rounded,
      badgeText: 'VISUAL MASTERY',
      accentColor: AppConstants.accentEmerald,
      gradient: LinearGradient(
        colors: [Color(0xFF059669), Color(0xFF0284C7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      tags: ['🗺️ Visual Map Tests', '🏆 Daily Leaderboards', '🔥 XP & Streaks'],
    ),
    const OnboardingSlideData(
      title: 'Dual Universe For\nStudents & Teachers',
      subtitle: 'Prepare to conquer your dream exam as a student, or join as a verified educator to author questions, review tests, and mentor aspirants.',
      icon: Icons.supervisor_account_rounded,
      badgeText: 'STUDENT & FACULTY HUB',
      accentColor: AppConstants.accentYellowSoft,
      gradient: LinearGradient(
        colors: [Color(0xFFD97706), Color(0xFFEA580C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      tags: ['🎓 Aspirant Prep', '👨‍🏫 Verified Faculty Panel', '💼 Question Authoring'],
    ),
  ];

  Future<void> _markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    widget.onComplete();
  }

  void _nextPage() {
    if (_currentIndex < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _markOnboardingComplete();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentIndex == _slides.length - 1;
    final currentSlide = _slides[_currentIndex];

    return Scaffold(
      backgroundColor: AppConstants.scaffoldDark,
      body: SafeArea(
        child: Column(
          children: [
            // TOP BAR: Logo + Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.space20, vertical: AppConstants.space12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo + Name
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: AppConstants.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppConstants.accentBlue.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.school, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'EXAMVERSE',
                        style: TextStyle(
                          color: AppConstants.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),

                  // Skip Button
                  if (!isLast)
                    TextButton(
                      onPressed: _markOnboardingComplete,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        backgroundColor: AppConstants.surfaceElevated,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // SLIDES CAROUSEL
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (idx) => setState(() => _currentIndex = idx),
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppConstants.space24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // HERO ILLUSTRATION ICON CARD
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            gradient: slide.gradient,
                            borderRadius: BorderRadius.circular(36),
                            boxShadow: [
                              BoxShadow(
                                color: slide.accentColor.withValues(alpha: 0.35),
                                blurRadius: 28,
                                spreadRadius: 2,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Background decorative circles
                              Positioned(
                                top: -20,
                                right: -20,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.12),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: -20,
                                left: -20,
                                child: Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                              ),
                              Icon(
                                slide.icon,
                                size: 84,
                                color: Colors.white,
                              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppConstants.space24),

                        // BADGE
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: slide.accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: slide.accentColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            slide.badgeText,
                            style: TextStyle(
                              color: slide.accentColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppConstants.space16),

                        // TITLE
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppConstants.textPrimary,
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: AppConstants.space12),

                        // SUBTITLE
                        Text(
                          slide.subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppConstants.textSecondary,
                            fontSize: 13.5,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: AppConstants.space16),

                        // TAG PILLS
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          alignment: WrapAlignment.center,
                          children: slide.tags.map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppConstants.surfaceElevated,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppConstants.cardBorder),
                              ),
                              child: Text(
                                tag,
                                style: const TextStyle(
                                  color: AppConstants.textSecondary,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // BOTTOM CONTROLS & INDICATORS
            Padding(
              padding: const EdgeInsets.all(AppConstants.space24),
              child: Column(
                children: [
                  // PAGE INDICATORS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) {
                      final active = i == _currentIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active ? currentSlide.accentColor : AppConstants.cardBorder,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppConstants.space20),

                  // PRIMARY ACTION BUTTON
                  PrimaryButton(
                    label: isLast ? 'Get Started • Let\'s Begin 🚀' : 'Continue',
                    gradient: currentSlide.gradient,
                    onPressed: _nextPage,
                  ),
                  const SizedBox(height: AppConstants.space12),

                  // SIGN IN / ROLE QUICK LINK
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(color: AppConstants.textSecondary, fontSize: 13),
                      ),
                      GestureDetector(
                        onTap: () {
                          _markOnboardingComplete();
                        },
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            color: AppConstants.accentCyan,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingSlideData {
  final String title;
  final String subtitle;
  final IconData icon;
  final String badgeText;
  final Color accentColor;
  final LinearGradient gradient;
  final List<String> tags;

  const OnboardingSlideData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.badgeText,
    required this.accentColor,
    required this.gradient,
    required this.tags,
  });
}
