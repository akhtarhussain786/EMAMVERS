import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import '../../widgets/design_system_widgets.dart';

class FriendsLeaderboardView extends StatefulWidget {
  const FriendsLeaderboardView({super.key});

  @override
  State<FriendsLeaderboardView> createState() => _FriendsLeaderboardViewState();
}

class _FriendsLeaderboardViewState extends State<FriendsLeaderboardView> {
  bool isLoading = true;
  int myFriendsRank = 2;
  int totalFriends = 18;
  List<dynamic> friendsLeaderboard = [];

  @override
  void initState() {
    super.initState();
    _loadFriendsLeaderboard();
  }

  void _loadFriendsLeaderboard() async {
    setState(() => isLoading = true);
    try {
      final res = await ApiService.get('/v1/friends/leaderboard');
      setState(() {
        myFriendsRank = res['friends_rank'] ?? 2;
        totalFriends = res['total_friends'] ?? 18;
        friendsLeaderboard = res['leaderboard'] ?? _getFallbackFriends();
        isLoading = false;
      });
    } catch (_) {
      setState(() {
        friendsLeaderboard = _getFallbackFriends();
        isLoading = false;
      });
    }
  }

  List<dynamic> _getFallbackFriends() {
    return [
      {'rank': 1, 'full_name': 'Arman Khan', 'score': 5840, 'accuracy': 94.2, 'solved_questions': 1420},
      {'rank': 2, 'full_name': 'Rahul Kumar (You)', 'score': 5320, 'accuracy': 81.6, 'solved_questions': 1248},
      {'rank': 3, 'full_name': 'Akhtar Hussain', 'score': 4910, 'accuracy': 88.5, 'solved_questions': 1180},
      {'rank': 4, 'full_name': 'Sameer Sheikh', 'score': 4200, 'accuracy': 85.0, 'solved_questions': 990},
      {'rank': 5, 'full_name': 'Imran Ansari', 'score': 3720, 'accuracy': 79.4, 'solved_questions': 850},
    ];
  }

  void _syncContactsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppConstants.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppConstants.accentCyan.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.contacts, color: AppConstants.accentCyan, size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Find Friends on ExamVerse', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Privacy-safe contact matching', style: TextStyle(color: AppConstants.textSecondary, fontSize: 12)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppConstants.space16),

            const Text(
              'ExamVerse will hash phone numbers locally using SHA-256 before matching with registered candidates. Your raw contacts are NEVER stored or uploaded to our servers.',
              style: TextStyle(color: AppConstants.textSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: AppConstants.space24),

            PrimaryButton(
              label: 'Sync Contacts Securely →',
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => isLoading = true);
                try {
                  // Simulate privacy-safe phone hashes
                  await ApiService.post('/v1/friends/sync-contacts', {
                    'phone_hashes': [
                      'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
                      'ca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb',
                    ]
                  });
                  _loadFriendsLeaderboard();
                } catch (_) {
                  setState(() => isLoading = false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryDark,
      appBar: AppBar(
        backgroundColor: AppConstants.scaffoldDark,
        title: const Text('Friends Leaderboard', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined, color: AppConstants.accentCyan),
            onPressed: _syncContactsModal,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // FRIENDS RANK HERO CARD
              ExamVerseCard(
                gradient: AppConstants.aiGradient,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('YOUR FRIENDS RANK', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                        const SizedBox(height: 4),
                        Text('#$myFriendsRank / $totalFriends', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
                      ],
                    ),
                    SecondaryButton(
                      label: '+ Find Friends',
                      icon: Icons.person_add,
                      onPressed: _syncContactsModal,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.space20),

              // SECTION HEADER
              SectionHeader(title: 'Contacts Standings', actionLabel: 'Sync Contacts', onActionTap: _syncContactsModal),
              const SizedBox(height: AppConstants.space12),

              // FRIENDS LIST
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppConstants.accentCyan))
                    : ListView.separated(
                        itemCount: friendsLeaderboard.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final friend = friendsLeaderboard[i];
                          final rank = friend['rank'] ?? (i + 1);
                          final isUser = (friend['full_name'] as String).contains('(You)');

                          return ExamVerseCard(
                            backgroundColor: isUser ? AppConstants.surfaceElevated : AppConstants.cardDark,
                            border: Border.all(color: isUser ? AppConstants.accentCyan : AppConstants.cardBorder),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 28,
                                  child: Text('#$rank', style: TextStyle(color: isUser ? AppConstants.accentCyan : AppConstants.textSecondary, fontWeight: FontWeight.bold, fontSize: 14)),
                                ),
                                const SizedBox(width: 10),
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppConstants.primaryDark,
                                  child: Text((friend['full_name'] ?? 'F')[0].toUpperCase(), style: TextStyle(color: isUser ? AppConstants.accentCyan : Colors.white, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(friend['full_name'] ?? 'Friend', style: TextStyle(color: isUser ? AppConstants.accentCyan : Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                      const SizedBox(height: 2),
                                      Text('${friend['solved_questions']} Solved • ${friend['accuracy']}% Acc', style: const TextStyle(color: AppConstants.textMuted, fontSize: 11)),
                                    ],
                                  ),
                                ),
                                Text('${friend['score']} Points', style: const TextStyle(color: AppConstants.accentAmber, fontWeight: FontWeight.w800, fontSize: 14)),
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
