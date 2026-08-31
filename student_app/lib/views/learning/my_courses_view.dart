import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../models/exam_models.dart';
import 'learning_theme.dart';

class MyCoursesView extends StatefulWidget {
  final Function(String title) onSelectCourse;

  const MyCoursesView({
    super.key,
    required this.onSelectCourse,
  });

  @override
  State<MyCoursesView> createState() => _MyCoursesViewState();
}

class _MyCoursesViewState extends State<MyCoursesView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = true;
  List<TestItem> userTests = [];

  final List<Map<String, dynamic>> _inProgressCourses = [
    {
      'title': 'UI/UX Design Fundamentals',
      'lessons': '12 of 18 lessons completed',
      'progress': 0.65,
      'percentage': '65%',
      'color': const Color(0xFF6366F1),
      'icon': Icons.design_services_rounded,
    },
    {
      'title': 'Python for Beginners',
      'lessons': '18 of 25 lessons completed',
      'progress': 0.72,
      'percentage': '72%',
      'color': const Color(0xFF0284C7),
      'icon': Icons.terminal_rounded,
    },
    {
      'title': 'Microsoft Excel Essential Training',
      'lessons': '10 of 16 lessons completed',
      'progress': 0.62,
      'percentage': '62%',
      'color': const Color(0xFF16A34A),
      'icon': Icons.table_chart_rounded,
    },
    {
      'title': 'Complete HTML & CSS Course',
      'lessons': '14 of 20 lessons completed',
      'progress': 0.70,
      'percentage': '70%',
      'color': const Color(0xFFEA580C),
      'icon': Icons.html_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchUserCourses();
  }

  void _fetchUserCourses() async {
    try {
      final res = await ApiService.get('/v1/home');
      if (mounted) {
        final rawFeatured = res['featured_exams'] as List? ?? [];
        if (rawFeatured.isNotEmpty) {
          setState(() {
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LearningTheme.scaffoldLightBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Courses',
                    style: TextStyle(
                      color: LearningTheme.textDark,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.search, color: LearningTheme.textDark, size: 24),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: LearningTheme.primaryPurple,
                indicatorWeight: 3,
                labelColor: LearningTheme.primaryPurple,
                unselectedLabelColor: LearningTheme.textMuted,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                tabs: const [
                  Tab(text: 'In Progress'),
                  Tab(text: 'Completed'),
                  Tab(text: 'Wishlist'),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCourseList(_inProgressCourses),
                  _buildEmptyState('No completed courses yet'),
                  _buildEmptyState('Your wishlist is empty'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseList(List<Map<String, dynamic>> courses) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return GestureDetector(
          onTap: () => widget.onSelectCourse(course['title']),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: LearningTheme.cardShadow,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail Box
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: course['color'],
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Icon(
                      course['icon'] as IconData,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Course Info & Progress Bar
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              course['title'],
                              style: const TextStyle(
                                color: LearningTheme.textDark,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Icon(Icons.more_vert_rounded, color: LearningTheme.textMuted, size: 20),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        course['lessons'],
                        style: const TextStyle(color: LearningTheme.textMuted, fontSize: 12),
                      ),
                      const SizedBox(height: 10),

                      // Progress percentage & Bar
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: course['progress'],
                                backgroundColor: const Color(0xFFF1F5F9),
                                valueColor: const AlwaysStoppedAnimation<Color>(LearningTheme.primaryPurple),
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            course['percentage'],
                            style: const TextStyle(
                              color: LearningTheme.textMedium,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Bottom Sub-actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Continue Learning',
                            style: TextStyle(
                              color: LearningTheme.primaryPurple,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: LearningTheme.softPurpleBg,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: LearningTheme.primaryPurple,
                              size: 20,
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
      },
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border_rounded, size: 56, color: LearningTheme.textMuted),
          const SizedBox(height: 12),
          Text(
            msg,
            style: const TextStyle(color: LearningTheme.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
