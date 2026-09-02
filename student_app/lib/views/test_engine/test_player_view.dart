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
  String? loadError;
  int attemptId = 0;
  List<QuestionItem> questions = [];
  int currentIndex = 0;
  String selectedLanguage = 'en';
  bool isSubmitting = false;

  // Timer
  int remainingSeconds = 3600;
  Timer? _timer;

  // Per-question time tracking and answer autosave.
  Timer? _autosaveTimer;
  DateTime _questionEnteredAt = DateTime.now();
  final Set<int> _dirtyQuestionIds = <int>{};
  bool _isFlushing = false;

  @override
  void initState() {
    super.initState();
    _startAttempt();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _autosaveTimer?.cancel();
    super.dispose();
  }

  void _startAttempt() async {
    try {
      final res = await ApiService.post('/v1/tests/${widget.testId}/attempts', {});
      if (!mounted) return;
      setState(() {
        attemptId = res['attempt_id'] as int;
        questions = (res['questions'] as List? ?? []).map((q) => QuestionItem.fromJson(q)).toList();
        // The server computes remaining time from the attempt's start, so
        // reopening a test cannot hand back a fresh full-length timer.
        remainingSeconds = (res['remaining_seconds'] as int?)
            ?? (res['test']?['total_duration_seconds'] as int?)
            ?? 3600;
        isLoading = false;
        loadError = null;
      });
      _questionEnteredAt = DateTime.now();
      _initTimer();
      _initAutosave();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        loadError = e.toString().replaceAll('Exception: ', '');
      });
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

  /// Answers previously lived only in memory and were never sent to the server,
  /// so every submitted attempt scored zero. Flush pending changes periodically.
  void _initAutosave() {
    _autosaveTimer = Timer.periodic(const Duration(seconds: 15), (_) => _flushPendingAnswers());
  }

  /// Charges elapsed time to the question currently on screen.
  void _accrueTimeOnCurrentQuestion() {
    if (currentIndex >= questions.length) return;
    final now = DateTime.now();
    final elapsed = now.difference(_questionEnteredAt).inSeconds;
    if (elapsed > 0) {
      questions[currentIndex].timeSpentSeconds += elapsed;
      _dirtyQuestionIds.add(questions[currentIndex].id);
    }
    _questionEnteredAt = now;
  }

  Map<String, dynamic> _payloadFor(QuestionItem q) => {
    'question_id': q.id,
    'selected_option_key': q.selectedOption,
    'is_marked_for_review': q.isMarkedForReview ? 1 : 0,
    'time_spent_seconds': q.pendingTimeSeconds,
  };

  /// Sends changed answers to the server. Time is only cleared once the write
  /// succeeds, so a failed autosave is retried rather than lost.
  Future<void> _flushPendingAnswers() async {
    if (_isFlushing || attemptId == 0) return;
    _accrueTimeOnCurrentQuestion();
    if (_dirtyQuestionIds.isEmpty) return;

    _isFlushing = true;
    final batch = questions.where((q) => _dirtyQuestionIds.contains(q.id)).toList();
    try {
      await ApiService.put('/v1/attempts/$attemptId/answers', {
        'responses': batch.map(_payloadFor).toList(),
      });
      for (final q in batch) {
        q.commitPendingTime();
      }
      _dirtyQuestionIds.removeAll(batch.map((q) => q.id));
    } catch (_) {
      // Left dirty on purpose: the next autosave tick or the final submit retries.
    } finally {
      _isFlushing = false;
    }
  }

  String _formatTimer(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _onOptionSelected(String optionKey) {
    _accrueTimeOnCurrentQuestion();
    setState(() {
      questions[currentIndex].selectedOption = optionKey;
      questions[currentIndex].isAnswered = true;
      _dirtyQuestionIds.add(questions[currentIndex].id);
    });
  }

  void _onMarkForReview() {
    _accrueTimeOnCurrentQuestion();
    setState(() {
      questions[currentIndex].isMarkedForReview = !questions[currentIndex].isMarkedForReview;
      _dirtyQuestionIds.add(questions[currentIndex].id);
    });
  }

  void _onClearResponse() {
    _accrueTimeOnCurrentQuestion();
    setState(() {
      questions[currentIndex].selectedOption = null;
      questions[currentIndex].isAnswered = false;
      _dirtyQuestionIds.add(questions[currentIndex].id);
    });
  }

  void _goToQuestion(int index) {
    if (index < 0 || index >= questions.length) return;
    _accrueTimeOnCurrentQuestion();
    setState(() => currentIndex = index);
    _questionEnteredAt = DateTime.now();
    _flushPendingAnswers();
  }

  void _onSaveAndNext() {
    if (currentIndex < questions.length - 1) {
      _goToQuestion(currentIndex + 1);
    } else {
      _flushPendingAnswers();
      _showSubmitDialog(context);
    }
  }

  void _submitFinalAttempt() async {
    if (isSubmitting) return;
    setState(() => isSubmitting = true);

    _timer?.cancel();
    _autosaveTimer?.cancel();
    _accrueTimeOnCurrentQuestion();

    try {
      // Send every answer with the submission. The server persists these before
      // scoring, so an autosave that never landed cannot cost the candidate marks.
      await ApiService.post('/v1/attempts/$attemptId/submit', {
        'responses': questions.map(_payloadFor).toList(),
      });

      if (mounted) widget.onTestSubmitted(attemptId);
    } catch (e) {
      if (!mounted) return;
      // Do not navigate to a result that was never recorded.
      setState(() => isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not submit: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppConstants.accentRose,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _submitFinalAttempt,
          ),
        ),
      );
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
                        _goToQuestion(i);
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
