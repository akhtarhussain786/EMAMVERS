import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import '../../widgets/design_system_widgets.dart';

class MapQuizView extends StatefulWidget {
  const MapQuizView({super.key});

  @override
  State<MapQuizView> createState() => _MapQuizViewState();
}

class _MapQuizViewState extends State<MapQuizView> {
  bool isLoading = true;
  String? loadError;
  List<dynamic> questions = [];
  int currentIndex = 0;
  int score = 0;
  int correctCount = 0;
  int? selectedOptionIndex;
  bool isSubmitted = false;

  /// Options for the current question, shuffled exactly once when the question
  /// is shown. Building them inside build() re-shuffled on every setState, so
  /// the tapped option no longer matched the highlighted one.
  List<String> _currentOptions = const [];

  static const int _pointsPerCorrectAnswer = 10;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  void _loadQuiz() async {
    try {
      final res = await ApiService.get('/v1/map/quiz');
      if (!mounted) return;
      final loaded = (res is Map ? res['quiz_questions'] : null) as List? ?? [];
      setState(() {
        questions = loaded;
        isLoading = false;
        loadError = null;
      });
      if (loaded.isNotEmpty) _prepareOptionsForCurrent();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        loadError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  /// Server-supplied options are already real, distinct place names. The local
  /// fallback only kicks in for an older API that does not send them.
  void _prepareOptionsForCurrent() {
    if (currentIndex >= questions.length) return;
    final q = questions[currentIndex];

    final provided = (q['options'] as List?)?.map((e) => e.toString()).toList();
    final List<String> options;
    if (provided != null && provided.length > 1) {
      options = provided;
    } else {
      final answer = _correctAnswerFor(q);
      final pool = questions
          .map((other) => (other['state'] ?? '').toString())
          .where((s) => s.isNotEmpty && s != answer)
          .toSet()
          .toList()
        ..shuffle();
      options = <String>[answer, ...pool.take(3)].where((s) => s.isNotEmpty).toSet().toList();
    }

    final shuffled = List<String>.from(options)..shuffle();
    setState(() => _currentOptions = shuffled);
  }

  String _correctAnswerFor(dynamic q) =>
      (q['correct_answer'] ?? q['state'] ?? '').toString();

  void _handleOptionSelect(int index) {
    if (isSubmitted) return;
    setState(() => selectedOptionIndex = index);
  }

  void _submitAnswer() {
    if (selectedOptionIndex == null || isSubmitted) return;

    final q = questions[currentIndex];
    final chosen = _currentOptions[selectedOptionIndex!];
    // Previously score was incremented unconditionally, so every answer scored.
    final wasCorrect = chosen == _correctAnswerFor(q);

    setState(() {
      isSubmitted = true;
      if (wasCorrect) {
        score += _pointsPerCorrectAnswer;
        correctCount++;
      }
    });

    _recordProgress(q, wasCorrect);
  }

  /// Persists the attempt so map mastery reflects real activity rather than a
  /// dialog that claimed progress was saved without ever calling the server.
  Future<void> _recordProgress(dynamic q, bool wasCorrect) async {
    final locationId = q['location_id'] ?? q['id'];
    if (locationId == null) return;
    try {
      await ApiService.post('/v1/map/progress', {
        'location_id': locationId,
        'is_correct': wasCorrect,
      });
    } catch (_) {
      // Progress is best-effort; never block the quiz on a failed write.
    }
  }

  void _nextQuestion() {
    if (currentIndex < questions.length - 1) {
      setState(() {
        currentIndex++;
        selectedOptionIndex = null;
        isSubmitted = false;
      });
      _prepareOptionsForCurrent();
    } else {
      _showResultDialog();
    }
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.cardDark,
        title: const Text('Map Quiz Completed! 🏆', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Your Total Score: $score Points',
                style: const TextStyle(color: AppConstants.accentCyan, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('$correctCount of ${questions.length} correct',
                style: const TextStyle(color: AppConstants.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Map learning progress saved to your candidate profile.',
                style: TextStyle(color: AppConstants.textSecondary, fontSize: 12.5), textAlign: TextAlign.center),
          ],
        ),
        actions: [
          PrimaryButton(
            label: 'Done',
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(backgroundColor: AppConstants.primaryDark, body: Center(child: CircularProgressIndicator(color: AppConstants.accentCyan)));
    }

    if (questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppConstants.primaryDark,
        appBar: AppBar(backgroundColor: AppConstants.scaffoldDark, title: const Text('Map Quiz Mode')),
        body: EmptyStateWidget(
          icon: loadError != null ? Icons.cloud_off : Icons.map,
          title: loadError != null ? 'Could not load the quiz' : 'No Map Questions Available',
          description: loadError ?? 'No map locations have been published yet.',
          buttonLabel: loadError != null ? 'Try again' : null,
          onButtonPressed: loadError != null ? _loadQuiz : null,
        ),
      );
    }

    final currentQ = questions[currentIndex];
    final locationName = currentQ['name'] ?? 'Location';
    final categoryName = currentQ['category_name'] ?? 'Geography';
    final correctAnswer = _correctAnswerFor(currentQ);
    final options = _currentOptions;

    return Scaffold(
      backgroundColor: AppConstants.primaryDark,
      appBar: AppBar(
        backgroundColor: AppConstants.scaffoldDark,
        title: Text('Map Quiz (${currentIndex + 1}/${questions.length})', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PROGRESS BAR
              LinearProgressIndicator(
                value: (currentIndex + 1) / questions.length,
                backgroundColor: AppConstants.surfaceElevated,
                valueColor: const AlwaysStoppedAnimation<Color>(AppConstants.accentCyan),
                minHeight: 6,
              ),
              const SizedBox(height: AppConstants.space24),

              // QUESTION CARD
              ExamVerseCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppConstants.accentCyan.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                      child: Text(categoryName, style: const TextStyle(color: AppConstants.accentCyan, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'In which state/region is "$locationName" located?',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, height: 1.3),
                    ),
                    const SizedBox(height: 8),
                    Text(currentQ['short_description'] ?? '', style: const TextStyle(color: AppConstants.textSecondary, fontSize: 12.5)),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.space24),

              // OPTION CARDS
              ...List.generate(options.length, (index) {
                final optionText = options[index];
                final isSelected = selectedOptionIndex == index;
                final isCorrect = optionText == correctAnswer;

                Color optionColor = AppConstants.cardDark;
                BorderSide borderSide = const BorderSide(color: AppConstants.cardBorder);

                if (isSelected) {
                  optionColor = AppConstants.surfaceElevated;
                  borderSide = const BorderSide(color: AppConstants.accentCyan, width: 1.5);
                }

                if (isSubmitted) {
                  if (isCorrect) {
                    optionColor = AppConstants.accentEmerald.withValues(alpha: 0.15);
                    borderSide = const BorderSide(color: AppConstants.accentEmerald, width: 2);
                  } else if (isSelected) {
                    optionColor = AppConstants.accentRose.withValues(alpha: 0.15);
                    borderSide = const BorderSide(color: AppConstants.accentRose, width: 2);
                  }
                }

                return GestureDetector(
                  onTap: () => _handleOptionSelect(index),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: optionColor,
                      borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                      border: Border.fromBorderSide(borderSide),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: isSelected ? AppConstants.accentCyan : AppConstants.primaryDark,
                          child: Text(
                            String.fromCharCode(65 + index),
                            style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(optionText, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                        ),
                        if (isSubmitted && isCorrect)
                          const Icon(Icons.check_circle, color: AppConstants.accentEmerald, size: 20),
                      ],
                    ),
                  ),
                );
              }),

              const Spacer(),

              // SUBMIT / NEXT BUTTON
              PrimaryButton(
                label: !isSubmitted ? 'Submit Answer' : (currentIndex == questions.length - 1 ? 'Finish Quiz 🎉' : 'Next Question →'),
                onPressed: selectedOptionIndex == null ? null : (!isSubmitted ? _submitAnswer : _nextQuestion),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
