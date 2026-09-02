import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';

class WrongQuestionsView extends StatefulWidget {
  const WrongQuestionsView({super.key});

  @override
  State<WrongQuestionsView> createState() => _WrongQuestionsViewState();
}

class _WrongQuestionsViewState extends State<WrongQuestionsView> {
  bool isLoading = true;
  List<dynamic> wrongQuestions = [];
  int expandedIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadWrongQuestions();
  }

  void _loadWrongQuestions() async {
    try {
      final res = await ApiService.get('/v1/user/wrong-questions');
      setState(() {
        wrongQuestions = res is List ? res : [];
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryDark,
      appBar: AppBar(
        backgroundColor: AppConstants.cardDark,
        elevation: 0,
        title: const Text('Mistake Bank / Wrong Notebook', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: AppConstants.accentBlue))
            : wrongQuestions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 64, color: AppConstants.accentGreen),
                      const SizedBox(height: 12),
                      const Text('No recorded mistakes yet!', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      const Text('Questions you answer wrong during full mock tests\nwill automatically appear here for revision.',
                          textAlign: TextAlign.center, style: TextStyle(color: AppConstants.textMuted, fontSize: 12)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: wrongQuestions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, i) {
                    final item = wrongQuestions[i];
                    final isExpanded = expandedIndex == i;
                    final qText = item['question_text'] ?? 'Question #${item['question_id']}';
                    final solText = item['solution_text'] ?? 'No solution provided.';
                    final options = item['options'] as List? ?? [];
                    final userKey = item['user_selected_key'] ?? 'N/A';
                    final correctKey = item['correct_key'] ?? 'A';
                    final subjectName = item['subject_name'] ?? 'General';
                    final diff = (item['difficulty'] ?? 'medium').toString().toUpperCase();

                    return Container(
                      decoration: BoxDecoration(
                        color: AppConstants.cardDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isExpanded ? AppConstants.accentBlue : AppConstants.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          InkWell(
                            onTap: () => setState(() => expandedIndex = isExpanded ? -1 : i),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppConstants.accentBlue.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(subjectName, style: const TextStyle(color: AppConstants.accentBlue, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text('DIFFICULTY: $diff', style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(qText, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Text('Your Answer: ', style: const TextStyle(color: AppConstants.textMuted, fontSize: 12)),
                                      Text(userKey, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                                      const SizedBox(width: 16),
                                      Text('Correct: ', style: const TextStyle(color: AppConstants.textMuted, fontSize: 12)),
                                      Text(correctKey, style: TextStyle(color: AppConstants.accentGreen, fontWeight: FontWeight.bold, fontSize: 13)),
                                      const Spacer(),
                                      Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppConstants.textMuted),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Expanded Options & Solution
                          if (isExpanded) ...[
                            const Divider(color: AppConstants.cardBorder, height: 1),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('OPTIONS:', style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                  const SizedBox(height: 8),
                                  ...options.map((opt) {
                                    final key = opt['option_key'];
                                    final text = opt['option_text'];
                                    final isCorrect = key == correctKey;
                                    final isUserChoice = key == userKey;

                                    Color borderCol = AppConstants.cardBorder;
                                    Color textCol = Colors.white70;
                                    if (isCorrect) {
                                      borderCol = AppConstants.accentGreen;
                                      textCol = AppConstants.accentGreen;
                                    } else if (isUserChoice) {
                                      borderCol = Colors.redAccent;
                                      textCol = Colors.redAccent;
                                    }

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: AppConstants.primaryDark,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: borderCol),
                                      ),
                                      child: Row(
                                        children: [
                                          Text('$key.', style: TextStyle(color: textCol, fontWeight: FontWeight.bold)),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(text, style: TextStyle(color: textCol, fontSize: 13))),
                                          if (isCorrect) Icon(Icons.check, color: AppConstants.accentGreen, size: 16),
                                          if (isUserChoice && !isCorrect) const Icon(Icons.close, color: Colors.redAccent, size: 16),
                                        ],
                                      ),
                                    );
                                  }),
                                  const SizedBox(height: 14),
                                  const Text('SOLUTION & EXPLANATION:', style: TextStyle(color: AppConstants.accentBlue, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppConstants.primaryDark,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(solText, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
