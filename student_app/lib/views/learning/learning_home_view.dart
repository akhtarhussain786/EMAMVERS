import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../models/exam_models.dart';
import '../../models/ranking_model.dart';
import '../../widgets/skeleton_loader.dart';
import 'learning_theme.dart';

class LearningHomeView extends StatefulWidget {
  final Function(int examId) onSelectExam;
  final Function(int testId) onSelectTest;
  final VoidCallback onOpenCourseDetail;
  final VoidCallback onOpenMyCourses;

  const LearningHomeView({
    super.key,
    required this.onSelectExam,
    required this.onSelectTest,
    required this.onOpenCourseDetail,
    required this.onOpenMyCourses,
  });

  @override
  State<LearningHomeView> createState() => _LearningHomeViewState();
}

class _LearningHomeViewState extends State<LearningHomeView> {
  bool isLoading = true;
  UserRanking userRanking = const UserRanking();
  List<ExamCategory> categories = [];
  List<ExamItem> featuredExams = [];
  Map<String, dynamic>? monthlyChallenge;

  @override
  void initState() {
    super.initState();
    _fetchBackendHomeData();
  }

  void _fetchBackendHomeData() async {
    try {
      final res = await ApiService.get('/v1/home');
      if (mounted) {
        setState(() {
          userRanking = UserRanking.fromJson(res['user_ranking'] ?? res['ranking'] ?? {});
          categories = (res['categories'] as List? ?? [])
              .map((c) => ExamCategory.fromJson(c))
              .toList();
          featuredExams = (res['featured_exams'] as List? ?? [])
              .map((e) => ExamItem.fromJson(e))
              .toList();
          monthlyChallenge = res['monthly_challenge'];
          isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: LearningTheme.scaffoldLightBg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonCard(height: 60, borderRadius: 16),
                SizedBox(height: 20),
                SkeletonCard(height: 180, borderRadius: 24),
                SizedBox(height: 20),
                Expanded(child: SkeletonListLoader(count: 3, itemHeight: 90)),
              ],
            ),
          ),
        ),
      );
    }

    final userName = userRanking.currentRank > 0
        ? 'Rank #${userRanking.currentRank}'
        : (userRanking.xpPoints > 0 ? 'Learner' : 'Ayesha 👋');

    return Scaffold(
      backgroundColor: LearningTheme.scaffoldLightBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TOP GREETING BAR + NOTIFICATIONS + AVATAR
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.menu_rounded, color: LearningTheme.textDark, size: 26),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome back,',
                            style: TextStyle(
                              color: LearningTheme.textMuted,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            userName,
                            style: const TextStyle(
                              color: LearningTheme.textDark,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: LearningTheme.cardShadow,
                            ),
                            child: const Icon(
                              Icons.notifications_none_rounded,
                              color: LearningTheme.textDark,
                              size: 22,
                            ),
                          ),
                          Positioned(
                            right: 4,
                            top: 4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Text(
                                '2',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: LearningTheme.primaryPurple.withValues(alpha: 0.1),
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
                          style: const TextStyle(
                            color: LearningTheme.primaryPurple,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 2. SEARCH INPUT WITH PURPLE BUTTON
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: LearningTheme.cardShadow,
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Search for courses, topics...',
                        style: TextStyle(color: LearningTheme.textMuted, fontSize: 14),
                      ),
                    ),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: LearningTheme.primaryPurple,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.search, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 3. HERO CONTINUE LEARNING CARD
              GestureDetector(
                onTap: widget.onOpenCourseDetail,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LearningTheme.heroCardGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: LearningTheme.purpleButtonShadow,
                  ),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Continue Learning',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            featuredExams.isNotEmpty
                                ? featuredExams[0].title
                                : 'UI/UX Design\nFundamentals',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 14),
                          // Progress Bar
                          Row(
                            children: [
                              const Text(
                                '65% Complete',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: 0.65,
                                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                    minHeight: 6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              if (featuredExams.isNotEmpty) {
                                widget.onSelectExam(featuredExams[0].id);
                              } else {
                                widget.onOpenCourseDetail();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: LearningTheme.primaryPurple,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              'Continue',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Icon(
                          Icons.laptop_mac_rounded,
                          size: 90,
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // 4. YOUR PROGRESS SECTION
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Your Progress',
                    style: TextStyle(
                      color: LearningTheme.textDark,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onOpenMyCourses,
                    child: const Text(
                      'View all',
                      style: TextStyle(
                        color: LearningTheme.primaryPurple,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _buildProgressStatCard(
                      categories.isNotEmpty ? '${categories.length}' : '12',
                      'Courses\nEnrolled',
                      Icons.menu_book_rounded,
                      const Color(0xFFF3E8FF),
                      LearningTheme.primaryPurple,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildProgressStatCard(
                      '${userRanking.testCount > 0 ? userRanking.testCount : 8}',
                      'Courses\nCompleted',
                      Icons.check_box_rounded,
                      LearningTheme.successGreenBg,
                      LearningTheme.successGreen,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildProgressStatCard(
                      '24',
                      'Hours\nLearned',
                      Icons.access_time_rounded,
                      LearningTheme.warningOrangeBg,
                      LearningTheme.warningOrange,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // 5. RECOMMENDED FOR YOU SECTION (DYNAMIC API DATA)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Recommended for You',
                    style: TextStyle(
                      color: LearningTheme.textDark,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'View all',
                    style: TextStyle(
                      color: LearningTheme.primaryPurple,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (featuredExams.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: featuredExams.length,
                  itemBuilder: (context, index) {
                    final exam = featuredExams[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildCourseCard(
                        exam.title,
                        exam.shortDescription ?? 'Learn top exam strategy & syllabus',
                        '4.8',
                        '(2.3k)',
                        exam.categoryName ?? 'Beginner',
                        LearningTheme.successGreenBg,
                        LearningTheme.successGreen,
                        index % 2 == 0 ? const Color(0xFF0284C7) : const Color(0xFF3B82F6),
                        index % 2 == 0 ? Icons.terminal_rounded : Icons.insights_rounded,
                        () => widget.onSelectExam(exam.id),
                      ),
                    );
                  },
                )
              else ...[
                _buildCourseCard(
                  'Python for Beginners',
                  'Learn Python from scratch',
                  '4.8',
                  '(2.3k)',
                  'Beginner',
                  LearningTheme.successGreenBg,
                  LearningTheme.successGreen,
                  const Color(0xFF0284C7),
                  Icons.terminal_rounded,
                  widget.onOpenCourseDetail,
                ),
                const SizedBox(height: 12),
                _buildCourseCard(
                  'Digital Marketing Masterclass',
                  'Learn modern marketing skills',
                  '4.7',
                  '(1.8k)',
                  'Intermediate',
                  LearningTheme.infoBlueBg,
                  LearningTheme.infoBlue,
                  const Color(0xFF3B82F6),
                  Icons.insights_rounded,
                  widget.onOpenCourseDetail,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressStatCard(
    String val,
    String label,
    IconData icon,
    Color bg,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: LearningTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                val,
                style: const TextStyle(
                  color: LearningTheme.textDark,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: LearningTheme.textMuted,
              fontSize: 11,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(
    String title,
    String desc,
    String rating,
    String reviews,
    String level,
    Color levelBg,
    Color levelColor,
    Color iconBg,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: LearningTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 34),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: LearningTheme.textDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    desc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: LearningTheme.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
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
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: levelBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          level,
                          style: TextStyle(
                            color: levelColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
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
