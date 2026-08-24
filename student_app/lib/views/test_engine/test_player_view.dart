import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import '../../models/exam_models.dart';

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
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds <= 1) {
        timer.cancel();
        _autoSubmit();
      } else {
        setState(() {
          remainingSeconds--;
          if (questions.isNotEmpty) {
            questions[currentIndex].timeSpentSeconds++;
          }
        });
      }
    });
  }

  void _autosaveCurrentState() async {
    if (questions.isEmpty) return;
    final q = questions[currentIndex];
    try {
      await ApiService.put('/v1/attempts/$attemptId/answers', {
        'question_id': q.questionId,
        'selected_option_key': q.selectedOptionKey,
        'numerical_answer': q.numericalAnswer,
        'is_marked_for_review': q.isMarkedForReview ? 1 : 0,
        'time_spent_seconds': q.timeSpentSeconds,
      });
    } catch (_) {}
  }

  void _onSaveAndNext() {
    _autosaveCurrentState();
    if (currentIndex < questions.length - 1) {
      setState(() => currentIndex++);
    }
  }

  void _onMarkForReview() {
    setState(() {
      questions[currentIndex].isMarkedForReview = !questions[currentIndex].isMarkedForReview;
    });
    _onSaveAndNext();
  }

  void _onClearResponse() {
    setState(() {
      questions[currentIndex].selectedOptionKey = null;
      questions[currentIndex].numericalAnswer = null;
    });
    _autosaveCurrentState();
  }

  void _autoSubmit() {
    _submitFinalAttempt();
  }

  void _submitFinalAttempt() async {
    _timer?.cancel();
    try {
      await ApiService.post('/v1/attempts/$attemptId/submit', {});
      widget.onTestSubmitted(attemptId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  String _formatTimer(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(backgroundColor: AppConstants.primaryDark, body: Center(child: CircularProgressIndicator(color: AppConstants.accentBlue)));
    }

    final currentQuestion = questions[currentIndex];
    final trans = currentQuestion.translations.firstWhere((t) => t.language == selectedLanguage, orElse: () => currentQuestion.translations.first);

    return Scaffold(
      backgroundColor: AppConstants.primaryDark,
      appBar: AppBar(
        backgroundColor: AppConstants.cardDark,
        title: Row(
          children: [
            Text('Q ${currentIndex + 1}/${questions.length}', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            const Spacer(),
            // Timer Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppConstants.primaryDark, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppConstants.accentBlue)),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, color: AppConstants.accentBlue, size: 16),
                  const SizedBox(width: 4),
                  Text(_formatTimer(remainingSeconds), style: const TextStyle(color: AppConstants.accentBlue, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Language Switcher
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
          IconButton(icon: const Icon(Icons.grid_view, color: Colors.white), onPressed: () => _openQuestionPalette(context)),
          IconButton(icon: const Icon(Icons.exit_to_app, color: Colors.redAccent), onPressed: () => _showSubmitDialog(context)),
        ],
      ),
      body: Column(
        children: [
          // Section Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppConstants.cardDark.withOpacity(0.5),
            child: Row(
              children: [
                Text(currentQuestion.sectionName ?? 'Section', style: const TextStyle(color: AppConstants.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('+${currentQuestion.positiveMarks} / -${currentQuestion.negativeMarks}', style: const TextStyle(color: AppConstants.accentEmerald, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          // Question Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(trans.questionText, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 24),

                  // MCQ Options
                  ...currentQuestion.options.where((o) => o.language == selectedLanguage || o.language == 'en').map((opt) {
                    final isSelected = currentQuestion.selectedOptionKey == opt.optionKey;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          currentQuestion.selectedOptionKey = opt.optionKey;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected ? AppConstants.accentBlue.withOpacity(0.15) : AppConstants.cardDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? AppConstants.accentBlue : AppConstants.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: isSelected ? AppConstants.accentBlue : AppConstants.primaryDark,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(opt.optionKey, style: TextStyle(color: isSelected ? Colors.white : AppConstants.textSecondary, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(child: Text(opt.optionText, style: const TextStyle(color: Colors.white, fontSize: 14))),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: AppConstants.cardDark, border: Border(top: BorderSide(color: AppConstants.cardBorder))),
            child: Row(
              children: [
                OutlinedButton(
                  onPressed: _onMarkForReview,
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppConstants.accentAmber), foregroundColor: AppConstants.accentAmber),
                  child: Text(currentQuestion.isMarkedForReview ? 'Unmark' : 'Mark for Review', style: const TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _onClearResponse,
                  child: const Text('Clear', style: TextStyle(color: AppConstants.textMuted, fontSize: 12)),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _onSaveAndNext,
                  style: ElevatedButton.styleFrom(backgroundColor: AppConstants.accentBlue, foregroundColor: Colors.white),
                  child: const Text('Save & Next', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
          ),
        ],
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Question Palette', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, crossAxisSpacing: 10, mainAxisSpacing: 10),
                  itemCount: questions.length,
                  itemBuilder: (context, i) {
                    final q = questions[i];
                    Color bg = Colors.grey.shade800;
                    if (q.isAnswered && q.isMarkedForReview) bg = Colors.purpleAccent;
                    else if (q.isMarkedForReview) bg = Colors.purple;
                    else if (q.isAnswered) bg = AppConstants.accentEmerald;

                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => currentIndex = i);
                      },
                      child: Container(
                        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
                        child: Center(child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
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
          title: const Text('Submit Test Attempt?', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Answered: $answered', style: const TextStyle(color: AppConstants.accentEmerald)),
              Text('Unattempted: $unattempted', style: const TextStyle(color: Colors.redAccent)),
              Text('Marked for Review: $marked', style: const TextStyle(color: AppConstants.accentAmber)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Continue Test')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _submitFinalAttempt();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppConstants.accentEmerald),
              child: const Text('Confirm Submit'),
            ),
          ],
        );
      },
    );
  }
}
