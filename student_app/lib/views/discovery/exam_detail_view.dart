import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import '../../models/exam_models.dart';
import '../../widgets/premium_cards.dart';
import '../../widgets/skeleton_loader.dart';

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
      return Scaffold(
        backgroundColor: AppConstants.primaryDark,
        appBar: AppBar(
          backgroundColor: AppConstants.cardDark,
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: widget.onBack),
          title: const Text('Exam Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        body: const Padding(
          padding: EdgeInsets.all(AppConstants.space20),
          child: SkeletonListLoader(count: 4, itemHeight: 120),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppConstants.primaryDark,
      appBar: AppBar(
        backgroundColor: AppConstants.cardDark,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: widget.onBack),
        title: Text(exam?['title'] ?? 'Exam Detail', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exam Header Card
            Container(
              padding: const EdgeInsets.all(AppConstants.space20),
              decoration: BoxDecoration(
                gradient: AppConstants.darkCardGradient,
                borderRadius: BorderRadius.circular(AppConstants.radiusHero),
                border: Border.all(color: AppConstants.accentIndigo.withOpacity(0.5)),
                boxShadow: AppConstants.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppConstants.accentIndigo.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          exam?['category_name'] ?? 'Government Exam',
                          style: const TextStyle(color: AppConstants.accentIndigo, fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppConstants.accentEmerald.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                        child: const Text('VERIFIED SYLLABUS', style: TextStyle(color: AppConstants.accentEmerald, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.space12),
                  Text(exam?['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(
                    exam?['overview_text'] ?? exam?['short_description'] ?? '',
                    style: const TextStyle(color: AppConstants.textSecondary, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.space24),

            // Effective Pattern Snapshot (SRD EXAM-002)
            if (pattern != null) ...[
              const Text('Effective Exam Pattern Snapshot', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: AppConstants.space12),
              Container(
                padding: const EdgeInsets.all(AppConstants.space16),
                decoration: BoxDecoration(
                  color: AppConstants.cardDark,
                  borderRadius: BorderRadius.circular(AppConstants.radiusCard),
                  border: Border.all(color: AppConstants.cardBorder),
                ),
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
              const SizedBox(height: AppConstants.space24),
            ],

            // Available Test Series (SRD TS-001)
            const Text('Available Test Series & Mocks', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppConstants.space12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final test = tests[i];
                return TestCard(
                  title: test.title,
                  category: exam?['title'] ?? 'MOCK TEST',
                  totalQuestions: test.totalQuestions ?? 100,
                  totalMarks: (test.totalQuestions ?? 100) * 2,
                  durationMinutes: test.totalDurationSeconds != null ? (test.totalDurationSeconds! / 60).round() : 60,
                  totalAttempts: 1240 + (i * 350),
                  isFree: !test.isPaid,
                  onTapStart: () => widget.onStartTest(test.id),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _patternMetric(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5)),
      ],
    );
  }
}
