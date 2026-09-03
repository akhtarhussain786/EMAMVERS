import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import '../../widgets/skeleton_loader.dart';

class TestInstructionsView extends StatefulWidget {
  final int testId;
  final VoidCallback onProceedToTest;
  final VoidCallback onCancel;

  const TestInstructionsView({
    super.key,
    required this.testId,
    required this.onProceedToTest,
    required this.onCancel,
  });

  @override
  State<TestInstructionsView> createState() => _TestInstructionsViewState();
}

class _TestInstructionsViewState extends State<TestInstructionsView> {
  bool isLoading = true;
  Map<String, dynamic>? instructionsData;

  @override
  void initState() {
    super.initState();
    _loadInstructions();
  }

  void _loadInstructions() async {
    try {
      final res = await ApiService.get('/v1/tests/${widget.testId}/instructions');
      if (!mounted) return;
      setState(() {
        instructionsData = res;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
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
          title: const Text('Test Instructions', style: TextStyle(color: AppConstants.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
          leading: IconButton(icon: const Icon(Icons.close, color: AppConstants.textPrimary), onPressed: widget.onCancel),
        ),
        body: const Padding(
          padding: EdgeInsets.all(AppConstants.space24),
          child: SkeletonListLoader(count: 3, itemHeight: 120),
        ),
      );
    }

    final title = instructionsData?['title'] ?? 'Test Instructions';
    final examTitle = instructionsData?['exam_title'] ?? '';
    final durationMins = instructionsData?['total_duration_seconds'] != null ? (instructionsData!['total_duration_seconds'] / 60).round() : 60;
    final totalQs = instructionsData?['total_questions'] ?? 0;
    final totalMarks = instructionsData?['total_marks'] ?? 0;
    final posMarks = instructionsData?['default_positive_marks'] ?? 2.0;
    final negMarks = instructionsData?['default_negative_marks'] ?? 0.5;

    return Scaffold(
      backgroundColor: AppConstants.primaryDark,
      appBar: AppBar(
        backgroundColor: AppConstants.cardDark,
        elevation: 0,
        title: const Text('Test Instructions', style: TextStyle(color: AppConstants.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.close, color: AppConstants.textPrimary), onPressed: widget.onCancel),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: AppConstants.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(examTitle, style: const TextStyle(color: AppConstants.accentBlue, fontSize: 13.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: AppConstants.space20),

            // Summary Grid
            Container(
              padding: const EdgeInsets.all(AppConstants.space16),
              decoration: BoxDecoration(
                gradient: AppConstants.darkCardGradient,
                borderRadius: BorderRadius.circular(AppConstants.radiusCard),
                border: Border.all(color: AppConstants.accentIndigo.withValues(alpha: 0.4)),
                boxShadow: AppConstants.cardShadow,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _infoTile('Duration', '$durationMins Mins'),
                  _infoTile('Questions', '$totalQs Qs'),
                  _infoTile('Total Marks', '$totalMarks Marks'),
                  _infoTile('Marking', '+$posMarks / -$negMarks'),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.space24),

            const Text('General Guidelines & Exam Rules:', style: TextStyle(color: AppConstants.onAccent, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppConstants.space12),
            _ruleBullet('The countdown timer at the top right of the screen displays remaining test time.'),
            _ruleBullet('You can navigate between questions using the Question Palette.'),
            _ruleBullet('Use Save & Next to save your answer and proceed to the next question.'),
            _ruleBullet('Questions marked for review will be evaluated if an option is selected.'),
            _ruleBullet('Each correct answer awards +$posMarks marks. Each incorrect answer deducts -$negMarks marks.'),
            _ruleBullet('Test will automatically submit when the timer expires.'),
            const SizedBox(height: AppConstants.space32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onProceedToTest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.accentEmerald,
                  foregroundColor: AppConstants.onAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMedium)),
                  elevation: 0,
                ),
                child: const Text('I am ready to begin test →', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _infoTile(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: AppConstants.onAccent, fontWeight: FontWeight.w800, fontSize: 14.5)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppConstants.textMuted, fontSize: 11)),
      ],
    );
  }

  Widget _ruleBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: AppConstants.accentIndigo, size: 16),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(color: AppConstants.textSecondary, fontSize: 13, height: 1.4))),
        ],
      ),
    );
  }
}
