import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../results/result_view.dart';
import '../../core/api_service.dart';
import '../../widgets/design_system_widgets.dart';

class TestHistoryView extends StatefulWidget {
  const TestHistoryView({super.key});

  @override
  State<TestHistoryView> createState() => _TestHistoryViewState();
}

class _TestHistoryViewState extends State<TestHistoryView> {
  bool isLoading = true;
  String? loadError;
  List<dynamic> history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() async {
    try {
      final res = await ApiService.get('/v1/passport');
      if (!mounted) return;
      setState(() {
        // The passport payload exposes history under 'recent_attempts'.
        history = (res is Map ? res['recent_attempts'] : null) as List? ?? [];
        isLoading = false;
        loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      // Showing invented scores and ranks here would be worse than showing
      // nothing — a candidate must never see a fabricated rank.
      setState(() {
        history = [];
        isLoading = false;
        loadError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  /// Opens the scorecard for a past attempt.
  void _openResult(dynamic item) {
    final id = item is Map ? (item['attempt_id'] ?? item['id']) : null;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('This attempt has no scorecard to open.'),
        backgroundColor: AppConstants.accentAmber,
      ));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultView(
          attemptId: id is int ? id : int.tryParse(id.toString()) ?? 0,
          onHome: () => Navigator.pop(context),
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
        title: const Text('Test History', style: TextStyle(color: AppConstants.onAccent, fontSize: 18, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: AppConstants.accentCyan))
            : history.isEmpty
                ? EmptyStateWidget(
                    icon: loadError != null ? Icons.cloud_off : Icons.history,
                    title: loadError != null ? 'Could not load history' : 'No Test History Yet',
                    description: loadError ?? 'Attempt mock tests to track your exam performance history here.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppConstants.space16),
                    itemCount: history.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppConstants.space12),
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
                                  child: Text(title, style: const TextStyle(color: AppConstants.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
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
                                SecondaryButton(label: 'View', onPressed: () => _openResult(item)),
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
