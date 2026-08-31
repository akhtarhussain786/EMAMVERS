import 'package:flutter/material.dart';
import 'learning_theme.dart';

class ELearningOnboardingView extends StatefulWidget {
  final VoidCallback onFinishOnboarding;
  final VoidCallback onLoginPressed;

  const ELearningOnboardingView({
    super.key,
    required this.onFinishOnboarding,
    required this.onLoginPressed,
  });

  @override
  State<ELearningOnboardingView> createState() => _ELearningOnboardingViewState();
}

class _ELearningOnboardingViewState extends State<ELearningOnboardingView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Step 3 selected interest topics
  final Set<String> _selectedTopics = {
    'Web Development',
    'Data Science',
    'UI/UX Design',
    'Artificial Intelligence'
  };

  final List<Map<String, dynamic>> _topics = [
    {'name': 'Web Development', 'icon': Icons.code_rounded},
    {'name': 'Data Science', 'icon': Icons.pie_chart_outline_rounded},
    {'name': 'Mobile Development', 'icon': Icons.smartphone_rounded},
    {'name': 'UI/UX Design', 'icon': Icons.design_services_rounded},
    {'name': 'Cyber Security', 'icon': Icons.shield_outlined},
    {'name': 'Cloud Computing', 'icon': Icons.cloud_outlined},
    {'name': 'Artificial Intelligence', 'icon': Icons.psychology_outlined},
    {'name': 'Business Management', 'icon': Icons.work_outline_rounded},
    {'name': 'Graphic Design', 'icon': Icons.palette_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LearningTheme.scaffoldLightBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header Skip Action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: widget.onFinishOnboarding,
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      color: LearningTheme.textMuted,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            // PageView Container
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (idx) {
                  setState(() => _currentPage = idx);
                },
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                ],
              ),
            ),

            // Bottom Pagination Dots & Dynamic Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  // Page Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: isActive ? 24 : 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? LearningTheme.primaryPurple
                              : LearningTheme.primaryPurple.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  // Dynamic CTA Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < 2) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          widget.onFinishOnboarding();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LearningTheme.primaryPurple,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: LearningTheme.primaryPurple.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage == 0
                                ? 'Get Started'
                                : (_currentPage == 1 ? 'Next' : 'Continue'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Footer note or Log In link
                  if (_currentPage == 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(
                            color: LearningTheme.textMedium,
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onLoginPressed,
                          child: const Text(
                            'Log In',
                            style: TextStyle(
                              color: LearningTheme.primaryPurple,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    )
                  else if (_currentPage == 2)
                    const Text(
                      'You can change this later in settings',
                      style: TextStyle(
                        color: LearningTheme.textMuted,
                        fontSize: 13,
                      ),
                    )
                  else
                    const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // STEP 1 BUILDER
  // ----------------------------------------------------
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 10),
          const Text(
            'Learn Today,\nLead Tomorrow',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: LearningTheme.textDark,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Discover courses, gain skills,\nand achieve your dreams.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: LearningTheme.textMedium,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),

          // Illustration Mockup Container
          Container(
            height: 260,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: LearningTheme.cardShadow,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Soft background circle
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: LearningTheme.softPurpleBg,
                    shape: BoxShape.circle,
                  ),
                ),
                // Icon Badges floating around
                Positioned(
                  top: 30,
                  left: 30,
                  child: _buildFloatingBadge(Icons.school_rounded, const Color(0xFF4832B6)),
                ),
                Positioned(
                  top: 40,
                  right: 30,
                  child: _buildFloatingBadge(Icons.play_arrow_rounded, LearningTheme.primaryPurple),
                ),
                Positioned(
                  bottom: 40,
                  left: 20,
                  child: _buildFloatingBadge(Icons.bar_chart_rounded, const Color(0xFF8B5CF6)),
                ),
                // Center Student Graphic Icon
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFCE7F3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.laptop_chromebook_rounded,
                        size: 72,
                        color: LearningTheme.primaryPurple,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Interactive Learning',
                      style: TextStyle(
                        color: LearningTheme.textDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingBadge(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  // ----------------------------------------------------
  // STEP 2 BUILDER
  // ----------------------------------------------------
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Explore. Learn.\nGrow.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: LearningTheme.textDark,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Access 1000+ courses from expert\ninstructors across the world.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: LearningTheme.textMedium,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Search + Notification Bar
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: LearningTheme.borderLight),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.search, color: LearningTheme.textMuted, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Search for courses',
                        style: TextStyle(color: LearningTheme.textMuted, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Stack(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: LearningTheme.borderLight),
                    ),
                    child: const Icon(Icons.notifications_none_rounded, color: LearningTheme.textDark),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        '3',
                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Popular Categories
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Popular Categories',
                style: TextStyle(
                  color: LearningTheme.textDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              Text(
                'View All',
                style: TextStyle(
                  color: LearningTheme.primaryPurple,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCategorySquare('Design', Icons.palette_rounded, const Color(0xFFF3E8FF), const Color(0xFF9333EA)),
              _buildCategorySquare('Development', Icons.code_rounded, const Color(0xFFECFDF5), const Color(0xFF059669)),
              _buildCategorySquare('Business', Icons.card_travel_rounded, const Color(0xFFFCE7F3), const Color(0xFFDB2777)),
              _buildCategorySquare('Marketing', Icons.campaign_rounded, const Color(0xFFFFEDD5), const Color(0xFFEA580C)),
            ],
          ),
          const SizedBox(height: 20),

          // Top Courses List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Top Courses',
                style: TextStyle(
                  color: LearningTheme.textDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              Text(
                'View All',
                style: TextStyle(
                  color: LearningTheme.primaryPurple,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildMiniCourseItem(
            'UI/UX Design Fundamentals',
            'Anna Smith',
            '4.8',
            '(2.3k)',
            'Beginner',
            LearningTheme.primaryPurple,
            Icons.design_services_rounded,
          ),
          const SizedBox(height: 8),
          _buildMiniCourseItem(
            'Python Programming Bootcamp',
            'John Doe',
            '4.9',
            '(3.1k)',
            'Intermediate',
            const Color(0xFFEAB308),
            Icons.terminal_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySquare(String label, IconData icon, Color bg, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: LearningTheme.textDark,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniCourseItem(
    String title,
    String author,
    String rating,
    String reviews,
    String level,
    Color themeColor,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: LearningTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: themeColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: LearningTheme.textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  author,
                  style: const TextStyle(color: LearningTheme.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: LearningTheme.starYellow, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      rating,
                      style: const TextStyle(
                        color: LearningTheme.textDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      reviews,
                      style: const TextStyle(color: LearningTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: LearningTheme.successGreenBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              level,
              style: const TextStyle(
                color: LearningTheme.successGreen,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // STEP 3 BUILDER
  // ----------------------------------------------------
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Text(
            'Personalize Your\nLearning Journey',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: LearningTheme.textDark,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tell us what you\'re interested in\nso we can personalize your experience.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: LearningTheme.textMedium,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          // 3x3 Grid of Topic Cards
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _topics.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.95,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, idx) {
              final topic = _topics[idx];
              final isSelected = _selectedTopics.contains(topic['name']);
              return InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedTopics.remove(topic['name']);
                    } else {
                      _selectedTopics.add(topic['name']);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? LearningTheme.primaryPurple
                          : LearningTheme.borderLight,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: LearningTheme.cardShadow,
                  ),
                  child: Stack(
                    children: [
                      // Selection check circle
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? LearningTheme.primaryPurple
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? LearningTheme.primaryPurple
                                  : LearningTheme.borderLight,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, size: 12, color: Colors.white)
                              : null,
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              topic['icon'] as IconData,
                              size: 28,
                              color: isSelected
                                  ? LearningTheme.primaryPurple
                                  : LearningTheme.textMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              topic['name'] as String,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: LearningTheme.textDark,
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
