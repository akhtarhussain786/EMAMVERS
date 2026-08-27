import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import '../../models/exam_models.dart';
import '../../widgets/skeleton_loader.dart';

class TestPlayerView extends StatefulWidget {
  final int testId;
  final Function(int attemptId) onTestSubmitted;
  final VoidCallback onExit;

  const TestPlayerView({
    super.key,
    required this.testId,
    required this.onTestSubmitted,
    required this.onExit,
  });

  @override
  State<TestPlayerView> createState() => _TestPlayerViewState();
}

class _TestPlayerViewState extends State<TestPlayerView> {
  bool isLoading = true;
  int attemptId = 0;
  List<QuestionItem> questions = [];
  int currentIndex = 0;
  String selectedLanguage = 'en';

  // Timer
  int remainingSeconds = 3600;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAttempt();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAttempt() async {
    try {
      final res = await ApiService.post('/v1/tests/${widget.testId}/attempts', {});
      setState(() {
        attemptId = res['attempt_id'];
        questions = (res['questions'] as List? ?? []).map((q) => QuestionItem.fromJson(q)).toList();
        remainingSeconds = res['test']['total_duration_seconds'] ?? 3600;
        isLoading = false;
      });
      _initTimer();
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  void _initTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remainingSeconds > 0) {
        setState(() => remainingSeconds--);
      } else {
        t.cancel();
        _submitFinalAttempt();
      }
    });
  }

  String _formatTimer(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _onOptionSelected(String optionKey) {
    setState(() {
      questions[currentIndex].selectedOption = optionKey;
      questions[currentIndex].isAnswered = true;
    });
  }

  void _onMarkForReview() {
    setState(() {
      questions[currentIndex].isMarkedForReview = !questions[currentIndex].isMarkedForReview;
    });
  }

  void _onClearResponse() {
    setState(() {
      questions[currentIndex].selectedOption = null;
      questions[currentIndex].isAnswered = false;
    });
  }

  void _onSaveAndNext() {
    if (currentIndex < questions.length - 1) {
      setState(() => currentIndex++);
    } else {
      _showSubmitDialog(context);
    }
  }

  void _submitFinalAttempt() async {
    try {
      final responses = questions.map((q) {
        return {
          'question_id': q.id,
          'selected_option': q.selectedOption,
          'is_marked_review': q.isMarkedForReview ? 1 : 0,
        };
      }).toList();

      await ApiService.post('/v1/attempts/$attemptId/submit', {
        'responses': responses,
      });

      if (mounted) widget.onTestSubmitted(attemptId);
    } catch (_) {
      if (mounted) widget.onTestSubmitted(attemptId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: AppConstants.primaryDark,
        appBar: AppBar(
          backgroundColor: AppConstants.cardDark,
          title: const Text('Loading Test Engine...', style: TextStyle(color: Colors.white, fontSize: 16)),
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: widget.onExit),
        ),
        body: const Padding(
          padding: EdgeInsets.all(AppConstants.space24),
          child: SkeletonListLoader(count: 3, itemHeight: 140),
        ),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppConstants.primaryDark,
        appBar: AppBar(backgroundColor: AppConstants.cardDark, title: const Text('Test Attempt')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No questions found for this test.', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: widget.onExit, child: const Text('Back')),
            ],
          ),
        ),
      );
    }

    final currentQuestion = questions[currentIndex];

    return Scaffold(
      backgroundColor: AppConstants.primaryDark,
      appBar: AppBar(
        backgroundColor: AppConstants.cardDark,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: widget.onExit),
        title: Row(
          children: [
            Text('Q ${currentIndex + 1}/${questions.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppConstants.primaryDark,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: remainingSeconds < 300 ? AppConstants.accentRose : AppConstants.accentBlue),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer_outlined, color: remainingSeconds < 300 ? AppConstants.accentRose : AppConstants.accentBlue, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    _formatTimer(remainingSeconds),
                    style: TextStyle(
                      color: remainingSeconds < 300 ? AppConstants.accentRose : AppConstants.accentBlue,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          DropdownButton<String>(
            value: selectedLanguage,
            dropdownColor: AppConstants.cardDark,
            underline: const SizedBox(),
            icon: const Icon(Icons.language, color: Colors.white, size: 20),
            items: const [
              DropdownMenuItem(value: 'en', child: Text('English', style: TextStyle(color: Colors.white, fontSize: 12))),
              DropdownMenuItem(value: 'hi', child: Text('हिन्दी', style: TextStyle(color: Colors.white, fontSize: 12))),
            ],
            onChanged: (v) => setState(() => selectedLanguage = v ?? 'en'),
          ),
          IconButton(icon: const Icon(Icons.grid_view_rounded, color: Colors.white), onPressed: () => _openQuestionPalette(context)),
          IconButton(icon: const Icon(Icons.exit_to_app_rounded, color: AppConstants.accentRose), onPressed: () => _showSubmitDialog(context)),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Section Bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: AppConstants.cardDark.withValues(alpha: 0.6),
              child: Row(
                children: [
                  Text(currentQuestion.sectionName ?? 'Section', style: const TextStyle(color: AppConstants.textSecondary, fontSize: 12.5, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text('+${currentQuestion.positiveMarks} / -${currentQuestion.negativeMarks}', style: const TextStyle(color: AppConstants.accentEmerald, fontSize: 11.5, fontWeight: FontWeight.w800)),
                ],
              ),
            ),

            // Question Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.space20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentQuestion.questionText,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, height: 1.4),
                    ),
                    const SizedBox(height: AppConstants.space24),

                    // Options List
                    ...currentQuestion.options.map((opt) {
                      final isSelected = currentQuestion.selectedOption == opt.optionKey;
                      return GestureDetector(
                        onTap: () => _onOptionSelected(opt.optionKey),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected ? AppConstants.accentIndigo.withValues(alpha: 0.15) : AppConstants.cardDark,
                            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                            border: Border.all(color: isSelected ? AppConstants.accentIndigo : AppConstants.cardBorder, width: isSelected ? 1.5 : 1.0),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: isSelected ? AppConstants.accentIndigo : AppConstants.primaryDark,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(opt.optionKey, style: TextStyle(color: isSelected ? Colors.white : AppConstants.textSecondary, fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(child: Text(opt.optionText, style: const TextStyle(color: Colors.white, fontSize: 14.5, height: 1.3))),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.all(AppConstants.space16),
              decoration: BoxDecoration(
                color: AppConstants.cardDark,
                border: Border(top: BorderSide(color: AppConstants.cardBorder)),
              ),
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: _onMarkForReview,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppConstants.accentAmber),
                      foregroundColor: AppConstants.accentAmber,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(currentQuestion.isMarkedForReview ? 'Unmark' : 'Mark Review', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _onClearResponse,
                    child: const Text('Clear', style: TextStyle(color: AppConstants.textMuted, fontSize: 12.5)),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _onSaveAndNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.accentIndigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Save & Next →', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openQuestionPalette(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(AppConstants.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Question Palette', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: AppConstants.space16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, crossAxisSpacing: 10, mainAxisSpacing: 10),
                  itemCount: questions.length,
                  itemBuilder: (context, i) {
                    final q = questions[i];
                    Color bg = AppConstants.primaryDark;
                    if (q.isAnswered && q.isMarkedForReview) {
                      bg = AppConstants.accentPurple;
                    } else if (q.isMarkedForReview) {
                      bg = AppConstants.accentAmber;
                    } else if (q.isAnswered) {
                      bg = AppConstants.accentEmerald;
                    }

                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => currentIndex = i);
                      },
                      child: Container(
                        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppConstants.cardBorder)),
                        child: Center(child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSubmitDialog(BuildContext context) {
    final answered = questions.where((q) => q.isAnswered).length;
    final unattempted = questions.length - answered;
    final marked = questions.where((q) => q.isMarkedForReview).length;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppConstants.cardDark,
          title: const Text('Submit Test Attempt?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogRow('Answered Questions', '$answered', AppConstants.accentEmerald),
              const SizedBox(height: 8),
              _dialogRow('Unattempted Questions', '$unattempted', AppConstants.accentRose),
              const SizedBox(height: 8),
              _dialogRow('Marked for Review', '$marked', AppConstants.accentAmber),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Continue Test', style: TextStyle(color: AppConstants.textSecondary))),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _submitFinalAttempt();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppConstants.accentEmerald, foregroundColor: Colors.white),
              child: const Text('Confirm & Submit', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _dialogRow(String label, String val, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppConstants.textSecondary, fontSize: 13)),
        Text(val, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}
