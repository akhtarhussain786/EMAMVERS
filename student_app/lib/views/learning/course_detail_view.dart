import 'package:flutter/material.dart';
import 'learning_theme.dart';

class CourseDetailView extends StatefulWidget {
  final String courseTitle;
  final VoidCallback onBack;

  const CourseDetailView({
    super.key,
    this.courseTitle = 'UI/UX Design Fundamentals',
    required this.onBack,
  });

  @override
  State<CourseDetailView> createState() => _CourseDetailViewState();
}

class _CourseDetailViewState extends State<CourseDetailView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isPlaying = true;
  bool _isMarkedComplete = false;
  final int _activeLessonIndex = 2; // Lesson 3 active by default

  final List<Map<String, dynamic>> _lessons = [
    {
      'title': '1. Introduction to UI Design',
      'duration': '08:15',
      'isCompleted': true,
      'isLocked': false,
    },
    {
      'title': '2. Design Principles',
      'duration': '10:24',
      'isCompleted': true,
      'isLocked': false,
    },
    {
      'title': '3. Colors and Typography in UI',
      'duration': '12:45',
      'isCompleted': false,
      'isLocked': false,
    },
    {
      'title': '4. Layouts and Grids',
      'duration': '09:30',
      'isCompleted': false,
      'isLocked': true,
    },
    {
      'title': '5. Hands-on Practice',
      'duration': '15:40',
      'isCompleted': false,
      'isLocked': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, initialIndex: 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeLesson = _lessons[_activeLessonIndex];

    return Scaffold(
      backgroundColor: LearningTheme.scaffoldLightBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back_rounded, color: LearningTheme.textDark),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.bookmark_border_rounded, color: LearningTheme.textDark),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.more_vert_rounded, color: LearningTheme.textDark),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subtitle & Main Title
                    Text(
                      widget.courseTitle,
                      style: const TextStyle(
                        color: LearningTheme.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activeLesson['title'] as String,
                      style: const TextStyle(
                        color: LearningTheme.textDark,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // VIDEO PLAYER CONTAINER
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LearningTheme.heroCardGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: LearningTheme.cardShadow,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Graphic text in background
                          Positioned(
                            top: 24,
                            left: 24,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Colors &\nTypography',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    height: 1.1,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'in UI Design',
                                  style: TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              ],
                            ),
                          ),

                          // Center Play Button
                          GestureDetector(
                            onTap: () => setState(() => _isPlaying = !_isPlaying),
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: LearningTheme.primaryPurple,
                                size: 30,
                              ),
                            ),
                          ),

                          // Bottom Video Controls Bar
                          Positioned(
                            bottom: 12,
                            left: 16,
                            right: 16,
                            child: Row(
                              children: [
                                const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                                const SizedBox(width: 6),
                                const Text(
                                  '05:21',
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderThemeData(
                                      trackHeight: 3,
                                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                                      activeTrackColor: LearningTheme.starYellow,
                                      inactiveTrackColor: Colors.white.withValues(alpha: 0.4),
                                      thumbColor: Colors.white,
                                    ),
                                    child: Slider(
                                      value: 0.42,
                                      onChanged: (val) {},
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '12:45',
                                  style: TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 20),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // TAB BAR (Overview | Lessons | Notes | Resources)
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
                        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                        tabs: const [
                          Tab(text: 'Overview'),
                          Tab(text: 'Lessons'),
                          Tab(text: 'Notes'),
                          Tab(text: 'Resources'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // LESSON PLAYLIST
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _lessons.length,
                      itemBuilder: (context, index) {
                        final lesson = _lessons[index];
                        final isActive = index == _activeLessonIndex;
                        final isCompleted = lesson['isCompleted'] as bool;
                        final isLocked = lesson['isLocked'] as bool;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isActive ? LearningTheme.softPurpleBg : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isActive ? LearningTheme.primaryPurple : LearningTheme.borderLight,
                              width: isActive ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Status Icon Circle
                              if (isCompleted)
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: LearningTheme.successGreen,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check, size: 18, color: Colors.white),
                                )
                              else if (isActive)
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: LearningTheme.primaryPurple,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.play_arrow_rounded, size: 18, color: Colors.white),
                                )
                              else
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF1F5F9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.play_arrow_rounded, size: 18, color: LearningTheme.textMuted),
                                ),

                              const SizedBox(width: 12),

                              // Lesson Title
                              Expanded(
                                child: Text(
                                  lesson['title'] as String,
                                  style: TextStyle(
                                    color: isActive ? LearningTheme.primaryPurple : LearningTheme.textDark,
                                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),

                              // Duration / Lock Icon
                              Text(
                                lesson['duration'] as String,
                                style: const TextStyle(color: LearningTheme.textMuted, fontSize: 12),
                              ),
                              const SizedBox(width: 8),

                              if (isLocked)
                                const Icon(Icons.lock_outline_rounded, color: LearningTheme.textMuted, size: 18)
                              else
                                const Icon(Icons.keyboard_arrow_down_rounded, color: LearningTheme.textMuted, size: 20),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 90),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // STICKY BOTTOM BUTTON ("Mark as Complete")
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isMarkedComplete = !_isMarkedComplete;
                _lessons[_activeLessonIndex]['isCompleted'] = _isMarkedComplete;
              });
            },
            icon: Icon(
              _isMarkedComplete ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white,
            ),
            label: Text(
              _isMarkedComplete ? 'Completed' : 'Mark as Complete',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isMarkedComplete ? LearningTheme.successGreen : LearningTheme.primaryPurple,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
