import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../widgets/design_system_widgets.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {'title': 'Rank Improvement Alert! 🚀', 'desc': 'Your All India Rank improved by 18 positions this week to #124!', 'time': '2 hours ago', 'icon': Icons.trending_up, 'color': AppConstants.accentEmerald},
      {'title': 'Daily Goal Reminder ⏱️', 'desc': 'Solve 18 more questions to maintain your 7-day streak.', 'time': '5 hours ago', 'icon': Icons.local_fire_department, 'color': AppConstants.accentAmber},
      {'title': 'SSC CGL Tier-1 Mock 05 Live! 📝', 'desc': 'New full-length mock test is now available. 128K+ aspirants registered.', 'time': '1 day ago', 'icon': Icons.assignment, 'color': AppConstants.accentCyan},
      {'title': 'Achievement Unlocked 🏆', 'desc': 'Congratulations! You unlocked the "1,000 Questions Solved" badge.', 'time': '2 days ago', 'icon': Icons.emoji_events, 'color': AppConstants.accentPurple},
    ];

    return Scaffold(
      backgroundColor: AppConstants.primaryDark,
      appBar: AppBar(
        backgroundColor: AppConstants.scaffoldDark,
        title: const Text('Notifications & Alerts', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppConstants.space16),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppConstants.space12),
        itemBuilder: (context, i) {
          final item = notifications[i];
          final color = item['color'] as Color;
          return ExamVerseCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Icon(item['icon'] as IconData, color: color, size: 20),
                ),
                const SizedBox(width: AppConstants.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(item['title'] as String, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                          ),
                          Text(item['time'] as String, style: const TextStyle(color: AppConstants.textMuted, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(item['desc'] as String, style: const TextStyle(color: AppConstants.textSecondary, fontSize: 12, height: 1.3)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
