import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import '../../models/exam_models.dart';
import '../../models/ranking_model.dart';
import '../../widgets/design_system_widgets.dart';
import '../../widgets/skeleton_loader.dart';
import '../current_affairs/current_affairs_view.dart';
import '../notifications/notifications_view.dart';
import '../map_learning/map_learning_home_view.dart';
import '../friends/friends_leaderboard_view.dart';
import '../notebook/mistake_notebook_view.dart';

class HomeView extends StatefulWidget {
  final Function(int examId) onSelectExam;
  final Function(int testId) onSelectTest;
  final VoidCallback onOpenAiCoach;
  final VoidCallback onOpenLeaderboard;

  const HomeView({
    super.key,
    required this.onSelectExam,
    required this.onSelectTest,
    required this.onOpenAiCoach,
    required this.onOpenLeaderboard,
  });

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool isLoading = true;
  UserRanking userRanking = const UserRanking();
  List<ExamCategory> categories = [];
  List<ExamItem> featuredExams = [];
  Map<String, dynamic>? monthlyChallenge;
  List<dynamic> currentAffairs = [];

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  void _loadHomeData() async {
    try {
      final res = await ApiService.get('/v1/home');
      setState(() {
        userRanking = UserRanking.fromJson(res['user_ranking'] ?? res['ranking'] ?? {});
        categories = (res['categories'] as List? ?? []).map((c) => ExamCategory.fromJson(c)).toList();
        featuredExams = (res['featured_exams'] as List? ?? []).map((e) => ExamItem.fromJson(e)).toList();
        monthlyChallenge = res['monthly_challenge'];
        currentAffairs = res['current_affairs'] ?? [];
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: AppConstants.primaryDark,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.space20),
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

    return Scaffold(
      backgroundColor: AppConstants.primaryDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppConstants.space20, AppConstants.space20, AppConstants.space20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. GREETING + NOTIFICATION BELL & AVATAR
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Good Morning, Candidate 👋',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Ready to improve your rank today?',
                        style: TextStyle(color: AppConstants.textSecondary, fontSize: 12.5),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppConstants.cardDark,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppConstants.cardBorder),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.notifications_none, color: Colors.white, size: 22),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsView())),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppConstants.accentCyan.withValues(alpha: 0.2),
                        child: const Icon(Icons.person, color: AppConstants.accentCyan, size: 22),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.space24),

              // 2. HERO PERFORMANCE RANK CARD
              RankCard(
                rank: userRanking.currentRank,
                percentile: userRanking.percentile,
                rankImprovementText: '↑ ${userRanking.rankImprovement} positions this week',
                bestRank: userRanking.bestRank,
              ),
              const SizedBox(height: AppConstants.space24),

              // 3. STATS HIGHLIGHT ROW
              Row(
                children: [
                  Expanded(child: StatCard(label: 'Accuracy', value: '${userRanking.accuracy}%', icon: Icons.verified_outlined, color: AppConstants.accentEmerald)),
                  const SizedBox(width: AppConstants.space12),
                  Expanded(child: StatCard(label: 'Solved Qs', value: userRanking.totalQuestionsSolved.toString(), icon: Icons.quiz_outlined, color: AppConstants.accentCyan)),
                ],
              ),
              const SizedBox(height: AppConstants.space12),
              Row(
                children: [
                  Expanded(child: StatCard(label: 'Tests Attempted', value: userRanking.testCount.toString(), icon: Icons.assignment_turned_in_outlined, color: AppConstants.accentPurple)),
                  const SizedBox(width: AppConstants.space12),
                  Expanded(child: StatCard(label: 'Current Streak', value: '${userRanking.streakDays} Days', icon: Icons.local_fire_department_outlined, color: AppConstants.accentAmber)),
                ],
              ),
              const SizedBox(height: AppConstants.space24),

              // 4. DAILY GOAL CARD
              ExamVerseCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text("Today's Goal", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                        Text("32 / 50 Questions", style: TextStyle(color: AppConstants.accentCyan, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: AppConstants.space12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: const LinearProgressIndicator(
                        value: 0.64,
                        minHeight: 8,
                        backgroundColor: AppConstants.surfaceElevated,
                        valueColor: AlwaysStoppedAnimation<Color>(AppConstants.accentCyan),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('18 Questions Remaining to reach today\'s streak target', style: TextStyle(color: AppConstants.textMuted, fontSize: 11.5)),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.space24),

              // 5. CONTINUE PRACTICE CARD
              ExamVerseCard(
                gradient: AppConstants.darkCardGradient,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppConstants.accentCyan.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.play_circle_fill, color: AppConstants.accentCyan, size: 28),
                    ),
                    const SizedBox(width: AppConstants.space16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('SSC CGL • Quantitative Aptitude', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                          SizedBox(height: 2),
                          Text('Algebra & Trigonometry • 64% Completed', style: TextStyle(color: AppConstants.textSecondary, fontSize: 11.5)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SecondaryButton(label: 'Resume', onPressed: widget.onOpenAiCoach),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.space24),

              // 6. QUICK ACTIONS GRID
              const SectionHeader(title: 'Quick Actions'),
              const SizedBox(height: AppConstants.space12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.95,
                children: [
                  _buildQuickAction('Map Learn', Icons.map_outlined, AppConstants.accentCyan, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MapLearningHomeView()));
                  }),
                  _buildQuickAction('Friends Rank', Icons.people_outline, AppConstants.accentAmber, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendsLeaderboardView()));
                  }),
                  _buildQuickAction('Mistakes', Icons.auto_fix_high, AppConstants.accentRose, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MistakeNotebookView()));
                  }),
                  _buildQuickAction('AI Coach', Icons.auto_awesome, AppConstants.accentPurple, widget.onOpenAiCoach),
                  _buildQuickAction('Practice', Icons.edit_note, AppConstants.accentBlue, widget.onOpenAiCoach),
                  _buildQuickAction('Leaderboard', Icons.emoji_events_outlined, AppConstants.accentEmerald, widget.onOpenLeaderboard),
                  _buildQuickAction('Daily Quiz', Icons.timer_outlined, AppConstants.accentCyan, widget.onOpenAiCoach),
                  _buildQuickAction('Affairs', Icons.newspaper, AppConstants.accentRose, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CurrentAffairsView()));
                  }),
                ],
              ),
              const SizedBox(height: AppConstants.space24),

              // 7. EXAM CATEGORIES GRID
              const SectionHeader(title: 'Exam Categories'),
              const SizedBox(height: AppConstants.space12),
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final cat = categories[i];
                    return GestureDetector(
                      onTap: () => widget.onSelectExam(cat.id),
                      child: Container(
                        width: 140,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppConstants.cardDark,
                          borderRadius: BorderRadius.circular(AppConstants.radiusCard),
                          border: Border.all(color: AppConstants.cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(_getCategoryIcon(cat.type), color: AppConstants.accentCyan, size: 24),
                            Text(
                              cat.name,
                              style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppConstants.space24),

              // 8. POPULAR EXAMS LIST
              const SectionHeader(title: 'Popular Competitive Exams'),
              const SizedBox(height: AppConstants.space12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: featuredExams.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final exam = featuredExams[i];
                  return ExamVerseCard(
                    onTap: () => widget.onSelectExam(exam.id),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(color: AppConstants.surfaceElevated, borderRadius: BorderRadius.circular(10)),
                          child: Center(child: Text(exam.orgName ?? 'EXAM', style: const TextStyle(color: AppConstants.accentCyan, fontWeight: FontWeight.bold, fontSize: 11))),
                        ),
                        const SizedBox(width: AppConstants.space12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(exam.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.5)),
                              const SizedBox(height: 2),
                              Text(exam.shortDescription ?? '', style: const TextStyle(color: AppConstants.textSecondary, fontSize: 11.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: AppConstants.accentCyan, size: 16),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppConstants.cardDark,
          borderRadius: BorderRadius.circular(AppConstants.radiusCard),
          border: Border.all(color: AppConstants.cardBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String type) {
    switch (type) {
      case 'government': return Icons.account_balance;
      case 'entrance': return Icons.school;
      case 'private_job': return Icons.work;
      case 'upskilling': return Icons.psychology;
      default: return Icons.explore;
    }
  }
}
