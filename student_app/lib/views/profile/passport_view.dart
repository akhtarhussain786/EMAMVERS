import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import '../../models/ranking_model.dart';
import '../../widgets/design_system_widgets.dart';
import 'bookmarks_view.dart';
import 'wrong_questions_view.dart';
import 'edit_profile_view.dart';
import 'test_history_view.dart';

class PassportView extends StatefulWidget {
  final VoidCallback? onLogout;
  const PassportView({super.key, this.onLogout});

  @override
  State<PassportView> createState() => _PassportViewState();
}

class _PassportViewState extends State<PassportView> {
  bool isLoading = true;
  UserRanking userRanking = const UserRanking();
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _loadPassport();
  }

  void _loadPassport() async {
    try {
      final res = await ApiService.get('/v1/passport');
      setState(() {
        userData = res;
        userRanking = UserRanking.fromJson(res ?? {});
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: AppConstants.primaryDark,
        body: Center(child: CircularProgressIndicator(color: AppConstants.accentCyan)),
      );
    }

    final studentName = userData?['passport_holder'] ?? 'Rahul Kumar';
    final targetExam = userData?['target_exam'] ?? 'Preparing for SSC CGL';

    return Scaffold(
      backgroundColor: AppConstants.primaryDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. STUDENT IDENTITY HEADER
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppConstants.accentCyan.withValues(alpha: 0.2),
                    child: const Icon(Icons.person, size: 36, color: AppConstants.accentCyan),
                  ),
                  const SizedBox(width: AppConstants.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(studentName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(targetExam, style: const TextStyle(color: AppConstants.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppConstants.accentCyan),
                    onPressed: () async {
                      final updated = await Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileView(userData: userData)));
                      if (updated == true) _loadPassport();
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.space24),

              // 2. LARGE RANK CARD
              RankCard(
                rank: userRanking.currentRank,
                percentile: userRanking.percentile,
                rankImprovementText: '↑ ${userRanking.rankImprovement} positions this week',
                bestRank: userRanking.bestRank,
              ),
              const SizedBox(height: AppConstants.space24),

              // 3. PERFORMANCE STATS GRID
              const SectionHeader(title: 'Question Performance Stats'),
              const SizedBox(height: AppConstants.space12),
              Row(
                children: [
                  Expanded(child: StatCard(label: 'Questions Solved', value: userRanking.totalQuestionsSolved.toString(), icon: Icons.quiz_outlined, color: AppConstants.accentCyan)),
                  const SizedBox(width: AppConstants.space12),
                  Expanded(child: StatCard(label: 'Accuracy', value: '${userRanking.accuracy}%', icon: Icons.verified_outlined, color: AppConstants.accentEmerald)),
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

              // 4. RANK CONTRIBUTION XP BREAKDOWN
              ExamVerseCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Rank Contribution', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: AppConstants.space12),
                    _buildXpRow('Questions Solved', '+${userRanking.questionsXp} XP', AppConstants.accentCyan),
                    _buildXpRow('Accuracy Bonus', '+${userRanking.accuracyXp} XP', AppConstants.accentEmerald),
                    _buildXpRow('Mock Tests', '+${userRanking.testsXp} XP', AppConstants.accentPurple),
                    _buildXpRow('Consistency Streak', '+${userRanking.streakXp} XP', AppConstants.accentAmber),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.space24),

              // 5. ACHIEVEMENTS BADGES
              const SectionHeader(title: 'Achievements & Badges'),
              const SizedBox(height: AppConstants.space12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildBadge('100 Questions', Icons.military_tech, true),
                  _buildBadge('500 Solved', Icons.star, true),
                  _buildBadge('1,000 Solved', Icons.workspace_premium, true),
                  _buildBadge('7-Day Streak', Icons.local_fire_department, true),
                  _buildBadge('Top 500', Icons.emoji_events, true),
                  _buildBadge('Accuracy Master', Icons.psychology, false),
                ],
              ),
              const SizedBox(height: AppConstants.space24),

              // 6. OPTIONS MENU
              const SectionHeader(title: 'Account Settings & Activity'),
              const SizedBox(height: AppConstants.space12),

              _buildOptionTile(
                icon: Icons.history_outlined,
                title: 'Test History & Analytics',
                subtitle: 'Review scorecards of previous mock tests',
                color: AppConstants.accentCyan,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TestHistoryView())),
              ),
              const SizedBox(height: 10),

              _buildOptionTile(
                icon: Icons.bookmark_outline,
                title: 'Saved Questions & Bookmarks',
                subtitle: 'Review bookmarked items and custom notes',
                color: AppConstants.accentPurple,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookmarksView())),
              ),
              const SizedBox(height: 10),

              _buildOptionTile(
                icon: Icons.error_outline,
                title: 'Mistake Bank (Wrong Questions)',
                subtitle: 'Practice incorrectly answered questions',
                color: AppConstants.accentRose,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WrongQuestionsView())),
              ),
              const SizedBox(height: 10),

              _buildOptionTile(
                icon: Icons.logout,
                title: 'Log Out',
                subtitle: 'Safely log out of your ExamVerse account',
                color: AppConstants.textMuted,
                onTap: () {
                  ApiService.authToken = null;
                  if (widget.onLogout != null) widget.onLogout!();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildXpRow(String label, String xp, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppConstants.textSecondary, fontSize: 13)),
          Text(xp, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, IconData icon, bool isUnlocked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isUnlocked ? AppConstants.surfaceElevated : AppConstants.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isUnlocked ? AppConstants.accentCyan.withValues(alpha: 0.4) : AppConstants.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isUnlocked ? AppConstants.accentAmber : AppConstants.textMuted),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: isUnlocked ? Colors.white : AppConstants.textMuted, fontSize: 11.5, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ExamVerseCard(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppConstants.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: AppConstants.textMuted, fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppConstants.textMuted, size: 20),
        ],
      ),
    );
  }
}
