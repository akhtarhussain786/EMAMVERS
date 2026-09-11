import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import '../../models/ranking_model.dart';
import '../../widgets/design_system_widgets.dart';
import '../../widgets/skeleton_loader.dart';

class LeaderboardView extends StatefulWidget {
  const LeaderboardView({super.key});

  @override
  State<LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends State<LeaderboardView> {
  bool isLoading = true;
  String? loadError;
  String currentTab = 'weekly';
  List<dynamic> leaderboard = [];
  UserRanking userRanking = const UserRanking();

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  void _loadLeaderboard() async {
    setState(() => isLoading = true);
    try {
      final res = await ApiService.get('/v1/leaderboards/$currentTab');
      if (!mounted) return;
      setState(() {
        leaderboard = (res is Map ? res['leaderboard'] : null) as List? ?? [];
        userRanking = UserRanking.fromJson((res is Map ? res['user_ranking'] : null) ?? {});
        isLoading = false;
        loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      // No invented ranks: a fabricated leaderboard misleads candidates about
      // where they actually stand.
      setState(() {
        leaderboard = [];
        isLoading = false;
        loadError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppConstants.space20, AppConstants.space20, AppConstants.space20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('National Leaderboard', style: TextStyle(color: AppConstants.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
                      SizedBox(height: 2),
                      Text('Verified All-India Central AIR & State Ranks', style: TextStyle(color: AppConstants.textSecondary, fontSize: 12)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppConstants.accentAmber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                    // Real cohort size, not an invented "128K+".
                    child: Text('${leaderboard.length} RANKED',
                        style: const TextStyle(color: AppConstants.accentAmber, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.space16),

              // Time Range Tabs
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppConstants.cardDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppConstants.cardBorder),
                ),
                child: Row(
                  children: ['today', 'weekly', 'monthly', 'alltime'].map((tab) {
                    final isSelected = currentTab == tab;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (currentTab != tab) {
                            setState(() => currentTab = tab);
                            _loadLeaderboard();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            gradient: isSelected ? AppConstants.primaryGradient : null,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              tab[0].toUpperCase() + tab.substring(1),
                              style: TextStyle(color: isSelected ? AppConstants.textPrimary : AppConstants.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppConstants.space16),

              // Logged-in User Rank Banner
              ExamVerseCard(
                gradient: AppConstants.aiGradient,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('YOUR CURRENT RANK', style: TextStyle(color: AppConstants.onAccent, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                        const SizedBox(height: 2),
                        Text('#${userRanking.currentRank}', style: const TextStyle(color: AppConstants.onAccent, fontSize: 22, fontWeight: FontWeight.w800)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppConstants.onAccent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                      child: Text('↑ ${userRanking.rankImprovement} Positions', style: const TextStyle(color: AppConstants.onAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('ACCURACY', style: TextStyle(color: AppConstants.onAccent, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                        const SizedBox(height: 2),
                        Text('${userRanking.accuracy}%', style: const TextStyle(color: AppConstants.onAccent, fontSize: 22, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.space16),

              // Leaderboard List
              Expanded(
                child: isLoading
                    ? const SkeletonListLoader(count: 6, itemHeight: 65)
                    : leaderboard.isEmpty
                    ? EmptyStateWidget(
                        icon: loadError != null ? Icons.cloud_off : Icons.leaderboard_outlined,
                        title: loadError != null ? 'Could not load rankings' : 'No Rankings Yet',
                        description: loadError ?? 'Rankings appear once candidates have completed this test.',
                        buttonLabel: loadError != null ? 'Try again' : null,
                        onButtonPressed: loadError != null ? _loadLeaderboard : null,
                      )
                    : ListView.separated(
                        itemCount: leaderboard.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final item = leaderboard[i];
                          final rank = item['rank'] ?? (i + 1);
                          final fullName = (item['full_name'] ?? 'Candidate').toString();
                          final rawAvatar = item['avatar_url'] as String?;
                          final avatarUrl = AppConstants.formatImageUrl(rawAvatar);

                          Widget rankBadge;
                          if (rank == 1) {
                            rankBadge = Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFF59E0B)),
                              ),
                              child: const Text('🥇 #1', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFFB45309))),
                            );
                          } else if (rank == 2) {
                            rankBadge = Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF94A3B8)),
                              ),
                              child: const Text('🥈 #2', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF475569))),
                            );
                          } else if (rank == 3) {
                            rankBadge = Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEDD5),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFF97316)),
                              ),
                              child: const Text('🥉 #3', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFFC2410C))),
                            );
                          } else {
                            rankBadge = Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppConstants.surfaceElevated,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('#$rank', style: const TextStyle(color: AppConstants.textSecondary, fontWeight: FontWeight.w800, fontSize: 12)),
                            );
                          }

                          final isUser = fullName.contains('(You)') || rank == userRanking.currentRank;

                          String initial = 'C';
                          if (fullName.trim().isNotEmpty) {
                            initial = fullName.trim()[0].toUpperCase();
                          }

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isUser ? AppConstants.surfaceElevated : AppConstants.cardDark,
                              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                              border: Border.all(color: isUser ? AppConstants.accentCyan : AppConstants.cardBorder, width: isUser ? 1.5 : 1),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Rank Badge
                                rankBadge,
                                const SizedBox(width: 12),

                                // Profile Image with Network & Fallback
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      gradient: isUser ? AppConstants.primaryGradient : null,
                                      color: isUser ? null : AppConstants.surfaceElevated,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: AppConstants.cardBorder),
                                    ),
                                    child: (avatarUrl != null && avatarUrl.isNotEmpty)
                                        ? Image.network(
                                            avatarUrl,
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Center(
                                              child: Text(
                                                initial,
                                                style: TextStyle(
                                                  color: isUser ? Colors.white : AppConstants.accentCyan,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ),
                                          )
                                        : Center(
                                            child: Text(
                                              initial,
                                              style: TextStyle(
                                                color: isUser ? Colors.white : AppConstants.accentCyan,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Name & State
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        fullName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: isUser ? AppConstants.accentCyan : AppConstants.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item['state_name'] != null ? '${item['state_name']}' : 'All-India Ranker',
                                        style: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5),
                                      ),
                                    ],
                                  ),
                                ),

                                // Accuracy Badge (No marks displayed)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppConstants.accentEmerald.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppConstants.accentEmerald.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    '${item['accuracy']}% Acc',
                                    style: const TextStyle(
                                      color: AppConstants.accentEmerald,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
