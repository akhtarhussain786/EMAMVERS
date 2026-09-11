import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import '../../models/ranking_model.dart';
import '../../widgets/design_system_widgets.dart';
import 'bookmarks_view.dart';
import 'wrong_questions_view.dart';
import 'edit_profile_view.dart';
import 'test_history_view.dart';
import 'referrals_view.dart';
import '../teacher/become_teacher_view.dart';
import '../subscription/subscriptions_view.dart';

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
      if (!mounted) return;
      setState(() {
        userData = res;
        userRanking = UserRanking.fromJson(res ?? {});
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
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

    final studentName = userData?['full_name'] ?? userData?['passport_holder'] ?? 'Candidate';
    final targetExam = userData?['target_exam'] ?? 'No target exam set yet';
    final rawAvatarUrl = userData?['avatar_url'] as String?;
    final avatarUrl = AppConstants.formatImageUrl(rawAvatarUrl);
    final email = userData?['email'] as String? ?? '';
    final mobile = userData?['mobile'] as String? ?? '';
    final stateName = userData?['state_name'] as String? ?? '';
    final district = userData?['district'] as String? ?? '';

    String initials = 'ST';
    if (studentName.isNotEmpty) {
      final parts = studentName.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
        initials = parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
      }
    }

    return Scaffold(
      backgroundColor: AppConstants.primaryDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. STUDENT IDENTITY HEADER
              Container(
                padding: const EdgeInsets.all(AppConstants.space16),
                decoration: BoxDecoration(
                  color: AppConstants.cardDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppConstants.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // AVATAR WITH SERVER-IMAGE SUPPORT
                        ClipRRect(
                          borderRadius: BorderRadius.circular(36),
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppConstants.accentBlue, AppConstants.accentCyan],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(36),
                            ),
                            child: (avatarUrl != null && avatarUrl.isNotEmpty)
                                ? Image.network(
                                    avatarUrl,
                                    width: 68,
                                    height: 68,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Center(
                                      child: Text(
                                        initials,
                                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      initials,
                                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: AppConstants.space16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                studentName,
                                style: const TextStyle(color: AppConstants.textPrimary, fontSize: 19, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: AppConstants.accentCyan.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  targetExam,
                                  style: const TextStyle(color: AppConstants.accentCyan, fontSize: 12, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (district.isNotEmpty || stateName.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 13, color: AppConstants.textMuted),
                                    const SizedBox(width: 3),
                                    Flexible(
                                      child: Text(
                                        [district, stateName].where((s) => s.isNotEmpty).join(', '),
                                        style: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: AppConstants.surfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AppConstants.accentCyan, size: 20),
                            tooltip: 'Edit Profile',
                            onPressed: () async {
                              final updated = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => EditProfileView(userData: userData)),
                              );
                              if (updated == true) _loadPassport();
                            },
                          ),
                        ),
                      ],
                    ),
                    if (email.isNotEmpty || mobile.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: AppConstants.cardBorder),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          if (email.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.email_outlined, size: 14, color: AppConstants.textMuted),
                                const SizedBox(width: 4),
                                Text(email, style: const TextStyle(color: AppConstants.textSecondary, fontSize: 12)),
                              ],
                            ),
                          if (mobile.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.phone_outlined, size: 14, color: AppConstants.textMuted),
                                const SizedBox(width: 4),
                                Text(mobile, style: const TextStyle(color: AppConstants.textSecondary, fontSize: 12)),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.space24),

              // 2. LARGE RANK CARD
              RankCard(
                rank: userRanking.currentRank,
                percentile: userRanking.percentile,
                rankImprovementText: userRanking.previousRank > 0
                    ? '↑ ${userRanking.rankImprovement} positions this week'
                    : 'Attempt a test to start tracking your rank',
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
                    const Text('Rank Contribution', style: TextStyle(color: AppConstants.onAccent, fontSize: 15, fontWeight: FontWeight.bold)),
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
                icon: Icons.history,
                title: 'Full Test History & Analytics',
                subtitle: 'Past scores, solutions & AIR rankings',
                color: AppConstants.accentCyan,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TestHistoryView())),
              ),
              const SizedBox(height: 10),

              _buildOptionTile(
                icon: Icons.workspace_premium_outlined,
                title: 'ExamVerse Pro Passes',
                subtitle: 'Unlimited mock tests, AI Exam-Twin & verified solutions',
                color: AppConstants.accentAmber,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionsView())),
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
                icon: Icons.card_giftcard_outlined,
                title: 'Referrals & Free Pro',
                subtitle: 'Invite aspirants and earn premium membership rewards',
                color: AppConstants.accentEmerald,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferralsView())),
              ),
              const SizedBox(height: 10),

              _buildOptionTile(
                icon: Icons.verified_user_outlined,
                title: 'Become a Verified Teacher',
                subtitle: 'Submit KYC and publish verified tests to students',
                color: AppConstants.accentYellow,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BecomeTeacherView())),
              ),
              const SizedBox(height: 10),

              _buildOptionTile(
                icon: Icons.logout,
                title: 'Log Out',
                subtitle: 'Safely log out of your ExamVerse account',
                color: AppConstants.textMuted,
                onTap: () {
                  ApiService.clearSession();
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
          Text(label, style: TextStyle(color: isUnlocked ? AppConstants.textPrimary : AppConstants.textMuted, fontSize: 11.5, fontWeight: FontWeight.bold)),
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
                Text(title, style: const TextStyle(color: AppConstants.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
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
