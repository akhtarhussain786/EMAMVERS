import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';

class LeaderboardView extends StatefulWidget {
  const LeaderboardView({super.key});

  @override
  State<LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends State<LeaderboardView> {
  bool isLoading = true;
  String currentTab = 'central';
  List<dynamic> leaderboard = [];
  String tieBreakRule = '';

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
        leaderboard = res['leaderboard'] ?? [];
        tieBreakRule = res['tie_break_rule'] ?? '';
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('National Challenge Leaderboard', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Deterministic Central All-India Rank & State Rank', style: TextStyle(color: AppConstants.textSecondary, fontSize: 12)),
              const SizedBox(height: 16),

              // Tab Switcher
              Container(
                decoration: BoxDecoration(color: AppConstants.cardDark, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => currentTab = 'central');
                          _loadLeaderboard();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(color: currentTab == 'central' ? AppConstants.accentBlue : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                          child: Center(child: Text('Central AIR Rank', style: TextStyle(color: currentTab == 'central' ? Colors.white : AppConstants.textSecondary, fontWeight: FontWeight.bold))),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => currentTab = 'state');
                          _loadLeaderboard();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(color: currentTab == 'state' ? AppConstants.accentBlue : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                          child: Center(child: Text('State Rank', style: TextStyle(color: currentTab == 'state' ? Colors.white : AppConstants.textSecondary, fontWeight: FontWeight.bold))),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Tie-break Rule Callout (SRD LB-004)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppConstants.cardDark, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppConstants.cardBorder)),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppConstants.accentBlue, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Tie-Break Policy: $tieBreakRule', style: const TextStyle(color: AppConstants.textSecondary, fontSize: 11))),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Leaderboard List
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppConstants.accentBlue))
                    : ListView.separated(
                        itemCount: leaderboard.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final item = leaderboard[i];
                          final rank = item['rank'] ?? (i + 1);
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: AppConstants.cardDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: rank <= 3 ? AppConstants.accentAmber : AppConstants.cardBorder)),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: rank == 1 ? AppConstants.accentAmber : (rank == 2 ? Colors.grey.shade400 : (rank == 3 ? Colors.brown.shade300 : AppConstants.primaryDark)),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(child: Text('#$rank', style: TextStyle(color: rank <= 3 ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item['full_name'] ?? 'Candidate', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                      const SizedBox(height: 2),
                                      Text('${item['state_name'] ?? 'Delhi'} • ${item['accuracy_percentage']}% Acc', style: const TextStyle(color: AppConstants.textSecondary, fontSize: 11)),
                                    ],
                                  ),
                                ),
                                Text('${double.parse(item['score'].toString()).toStringAsFixed(1)} Mks', style: const TextStyle(color: AppConstants.accentBlue, fontWeight: FontWeight.bold, fontSize: 14)),
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
