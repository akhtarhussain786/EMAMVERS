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
      setState(() {
        leaderboard = res['leaderboard'] ?? _getFallbackLeaderboard();
        userRanking = UserRanking.fromJson(res['user_ranking'] ?? {});
        isLoading = false;
      });
    } catch (_) {
      setState(() {
        leaderboard = _getFallbackLeaderboard();
        isLoading = false;
      });
    }
  }

  List<dynamic> _getFallbackLeaderboard() {
    return [
      {'rank': 1, 'full_name': 'Amit Sharma', 'state_name': 'Delhi', 'score': 192.5, 'accuracy': 98.2, 'xp': 2850},
      {'rank': 2, 'full_name': 'Priya Patel', 'state_name': 'Gujarat', 'score': 188.0, 'accuracy': 96.5, 'xp': 2710},
      {'rank': 3, 'full_name': 'Rohan Verma', 'state_name': 'UP', 'score': 184.5, 'accuracy': 94.8, 'xp': 2620},
      {'rank': 4, 'full_name': 'Ananya Singh', 'state_name': 'Bihar', 'score': 178.0, 'accuracy': 92.1, 'xp': 2450},
      {'rank': 5, 'full_name': 'Vikram Rathore', 'state_name': 'Rajasthan', 'score': 172.5, 'accuracy': 89.4, 'xp': 2310},
      {'rank': 124, 'full_name': 'Rahul Kumar (You)', 'state_name': 'Delhi', 'score': 156.0, 'accuracy': 81.6, 'xp': 1050},
    ];
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
                      Text('National Leaderboard', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                      SizedBox(height: 2),
                      Text('Verified All-India Central AIR & State Ranks', style: TextStyle(color: AppConstants.textSecondary, fontSize: 12)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppConstants.accentAmber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                    child: const Text('128K+ LIVE', style: TextStyle(color: AppConstants.accentAmber, fontSize: 11, fontWeight: FontWeight.bold)),
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
                              style: TextStyle(color: isSelected ? Colors.white : AppConstants.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
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
                        const Text('YOUR CURRENT RANK', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                        const SizedBox(height: 2),
                        Text('#${userRanking.currentRank}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                      child: Text('↑ ${userRanking.rankImprovement} Positions', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('ACCURACY', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                        const SizedBox(height: 2),
                        Text('${userRanking.accuracy}%', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
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
                    : ListView.separated(
                        itemCount: leaderboard.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final item = leaderboard[i];
                          final rank = item['rank'] ?? (i + 1);

                          Widget rankBadge;
                          if (rank == 1) {
                            rankBadge = const Text('🥇', style: TextStyle(fontSize: 20));
                          } else if (rank == 2) {
                            rankBadge = const Text('🥈', style: TextStyle(fontSize: 20));
                          } else if (rank == 3) {
                            rankBadge = const Text('🥉', style: TextStyle(fontSize: 20));
                          } else {
                            rankBadge = Text('#$rank', style: const TextStyle(color: AppConstants.textSecondary, fontWeight: FontWeight.bold, fontSize: 13));
                          }

                          final isUser = (item['full_name'] as String).contains('(You)') || rank == userRanking.currentRank;

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isUser ? AppConstants.surfaceElevated : AppConstants.cardDark,
                              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                              border: Border.all(color: isUser ? AppConstants.accentCyan : AppConstants.cardBorder),
                            ),
                            child: Row(
                              children: [
                                SizedBox(width: 32, child: Center(child: rankBadge)),
                                const SizedBox(width: 10),
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppConstants.primaryDark,
                                  child: Text((item['full_name'] ?? 'C')[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item['full_name'] ?? 'Candidate', style: TextStyle(color: isUser ? AppConstants.accentCyan : Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
                                      const SizedBox(height: 2),
                                      Text('${item['state_name'] ?? 'India'} • ${item['accuracy']}% Acc', style: const TextStyle(color: AppConstants.textMuted, fontSize: 11)),
                                    ],
                                  ),
                                ),
                                Text('${item['score']} Mks', style: const TextStyle(color: AppConstants.accentCyan, fontWeight: FontWeight.w800, fontSize: 13.5)),
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
