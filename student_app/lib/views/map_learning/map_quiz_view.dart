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
  List<dynamic> questions = [];
  int currentIndex = 0;
  int score = 0;
  int? selectedOptionIndex;
  bool isSubmitted = false;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  void _loadQuiz() async {
    try {
      final res = await ApiService.get('/v1/map/quiz');
      setState(() {
        questions = res['quiz_questions'] ?? [];
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  void _handleOptionSelect(int index) {
    if (isSubmitted) return;
    setState(() {
      selectedOptionIndex = index;
    });
  }

  void _submitAnswer() {
    if (selectedOptionIndex == null || isSubmitted) return;
    setState(() {
      isSubmitted = true;
      score += 10;
    });
  }

  void _nextQuestion() {
    if (currentIndex < questions.length - 1) {
      setState(() {
        currentIndex++;
        selectedOptionIndex = null;
        isSubmitted = false;
      });
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
            Text('Your Total Score: $score Points', style: const TextStyle(color: AppConstants.accentCyan, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Map learning mastery points added to your candidate profile.', style: TextStyle(color: AppConstants.textSecondary, fontSize: 12.5)),
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
        body: const EmptyStateWidget(icon: Icons.map, title: 'No Map Questions Available', description: 'Map quiz question bank is currently loading.'),
      );
    }

    final currentQ = questions[currentIndex];
    final locationName = currentQ['name'] ?? 'Location';
    final stateName = currentQ['state'] ?? 'State';
    final categoryName = currentQ['category_name'] ?? 'Geography';

    final dummyOptions = [
      stateName,
      'Rajasthan',
      'Madhya Pradesh',
      'Tamil Nadu',
    ]..shuffle();

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
              ...List.generate(dummyOptions.length, (index) {
                final optionText = dummyOptions[index];
                final isSelected = selectedOptionIndex == index;
                final isCorrect = optionText == stateName;

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
