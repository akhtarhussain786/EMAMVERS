import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import '../../models/exam_models.dart';

class ExamDetailView extends StatefulWidget {
  final int examId;
  final Function(int testId) onStartTest;
  final VoidCallback onBack;

  const ExamDetailView({
    super.key,
    required this.examId,
    required this.onStartTest,
    required this.onBack,
  });

  @override
  State<ExamDetailView> createState() => _ExamDetailViewState();
}

class _ExamDetailViewState extends State<ExamDetailView> {
  bool isLoading = true;
  Map<String, dynamic>? exam;
  Map<String, dynamic>? pattern;
  List<TestItem> tests = [];

  @override
  void initState() {
    super.initState();
    _loadExamDetail();
  }

  void _loadExamDetail() async {
    try {
      final res = await ApiService.get('/v1/exams/${widget.examId}');
      setState(() {
        exam = res['exam'];
        pattern = res['pattern'];
        tests = (res['tests'] as List? ?? []).map((t) => TestItem.fromJson(t)).toList();
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(backgroundColor: AppConstants.primaryDark, body: Center(child: CircularProgressIndicator(color: AppConstants.accentBlue)));
    }

    return Scaffold(
      backgroundColor: AppConstants.primaryDark,
      appBar: AppBar(
        backgroundColor: AppConstants.cardDark,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: widget.onBack),
        title: Text(exam?['title'] ?? 'Exam Detail', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exam Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppConstants.cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppConstants.cardBorder)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppConstants.accentBlue.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                        child: Text(exam?['category_name'] ?? 'Government Exam', style: const TextStyle(color: AppConstants.accentBlue, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(exam?['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(exam?['overview_text'] ?? exam?['short_description'] ?? '', style: const TextStyle(color: AppConstants.textSecondary, fontSize: 13, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Effective Pattern Snapshot (SRD EXAM-002)
            if (pattern != null) ...[
              const Text('Effective Exam Pattern Snapshot', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppConstants.cardDark, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppConstants.accentIndigo.withOpacity(0.4))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _patternMetric('Duration', '${(pattern!['total_duration_seconds'] / 60).round()} Mins'),
                    _patternMetric('Questions', '${pattern!['total_questions']} Qs'),
                    _patternMetric('Total Marks', '${pattern!['total_marks']} Marks'),
                    _patternMetric('Marking', '+${pattern!['default_positive_marks']} / -${pattern!['default_negative_marks']}'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Available Test Series (SRD TS-001)
            const Text('Available Test Series & Mocks', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final test = tests[i];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppConstants.cardDark, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppConstants.cardBorder)),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: AppConstants.accentBlue.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.assignment_turned_in, color: AppConstants.accentBlue),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(test.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text('${test.totalQuestions ?? 100} Qs • ${test.totalDurationSeconds != null ? (test.totalDurationSeconds! / 60).round() : 60} Mins • ${test.isPaid ? 'Paid' : 'FREE'}', style: const TextStyle(color: AppConstants.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => widget.onStartTest(test.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.accentBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Start Test', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _patternMetric(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppConstants.textMuted, fontSize: 11)),
      ],
    );
  }
}
