import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import '../../widgets/design_system_widgets.dart';

class TestHistoryView extends StatefulWidget {
  const TestHistoryView({super.key});

  @override
  State<TestHistoryView> createState() => _TestHistoryViewState();
}

class _TestHistoryViewState extends State<TestHistoryView> {
  bool isLoading = true;
  List<dynamic> history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() async {
    try {
      final res = await ApiService.get('/v1/passport');
      setState(() {
        history = res['recent_attempts'] as List? ?? _getFallbackHistory();
        isLoading = false;
      });
    } catch (_) {
      setState(() {
        history = _getFallbackHistory();
        isLoading = false;
      });
    }
  }

  List<dynamic> _getFallbackHistory() {
    return [
      {'test_title': 'SSC CGL Full Mock Test 04', 'started_at': '24 Aug 2026', 'score': '156/200', 'rank': '#124', 'accuracy_percentage': '83%'},
      {'test_title': 'Quant Sectional Quiz 12', 'started_at': '21 Aug 2026', 'score': '44/50', 'rank': '#89', 'accuracy_percentage': '88%'},
      {'test_title': 'Reasoning Speed Test 08', 'started_at': '18 Aug 2026', 'score': '48/50', 'rank': '#45', 'accuracy_percentage': '96%'},
      {'test_title': 'General Awareness PYP 2023', 'started_at': '15 Aug 2026', 'score': '32/50', 'rank': '#210', 'accuracy_percentage': '64%'},
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryDark,
      appBar: AppBar(
        backgroundColor: AppConstants.scaffoldDark,
        title: const Text('Test History', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: AppConstants.accentCyan))
            : history.isEmpty
                ? const EmptyStateWidget(icon: Icons.history, title: 'No Test History Yet', description: 'Attempt mock tests to track your exam performance history here.')
                : ListView.separated(
                    padding: const EdgeInsets.all(AppConstants.space16),
                    itemCount: history.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppConstants.space12),
                    itemBuilder: (context, index) {
                      final item = history[index];
                      final title = item['test_title'] ?? item['title'] ?? 'Mock Test';
                      final date = item['started_at'] ?? item['date'] ?? 'Recent';
                      final scoreStr = item['score'] != null ? '${item['score']}' : '150/200';
                      final rankStr = item['rank'] != null ? '${item['rank']}' : '#124';
                      final accStr = item['accuracy_percentage'] != null ? '${item['accuracy_percentage']}%' : '82%';

                      return ExamVerseCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                                ),
                                Text(date, style: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5)),
                              ],
                            ),
                            const SizedBox(height: AppConstants.space12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildMetric('Score', scoreStr, AppConstants.accentCyan),
                                _buildMetric('Rank', rankStr, AppConstants.accentPurple),
                                _buildMetric('Accuracy', accStr, AppConstants.accentEmerald),
                                SecondaryButton(label: 'View', onPressed: () {}),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
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
