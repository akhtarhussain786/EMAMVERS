import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../widgets/design_system_widgets.dart';

class TestHistoryView extends StatelessWidget {
  const TestHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final history = [
      {'title': 'SSC CGL Full Mock Test 04', 'date': '24 Aug 2026', 'score': '156/200', 'rank': '#124', 'accuracy': '83%'},
      {'title': 'Quant Sectional Quiz 12', 'date': '21 Aug 2026', 'score': '44/50', 'rank': '#89', 'accuracy': '88%'},
      {'title': 'Reasoning Speed Test 08', 'date': '18 Aug 2026', 'score': '48/50', 'rank': '#45', 'accuracy': '96%'},
      {'title': 'General Awareness PYP 2023', 'date': '15 Aug 2026', 'score': '32/50', 'rank': '#210', 'accuracy': '64%'},
    ];

    return Scaffold(
      backgroundColor: AppConstants.primaryDark,
      appBar: AppBar(
        backgroundColor: AppConstants.scaffoldDark,
        title: const Text('Test History', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppConstants.space16),
        itemCount: history.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppConstants.space12),
        itemBuilder: (context, index) {
          final item = history[index];
          return ExamVerseCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(item['title']!, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                    Text(item['date']!, style: const TextStyle(color: AppConstants.textMuted, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: AppConstants.space12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetric('Score', item['score']!, AppConstants.accentCyan),
                    _buildMetric('Rank', item['rank']!, AppConstants.accentPurple),
                    _buildMetric('Accuracy', item['accuracy']!, AppConstants.accentEmerald),
                    SecondaryButton(label: 'View', onPressed: () {}),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetric(String label, String val, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppConstants.textSecondary, fontSize: 11)),
        const SizedBox(height: 2),
        Text(val, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800)),
      ],
    );
  }
}
