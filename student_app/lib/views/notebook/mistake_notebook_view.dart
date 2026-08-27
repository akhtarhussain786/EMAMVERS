import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import '../../widgets/design_system_widgets.dart';

class MistakeNotebookView extends StatefulWidget {
  const MistakeNotebookView({super.key});

  @override
  State<MistakeNotebookView> createState() => _MistakeNotebookViewState();
}

class _MistakeNotebookViewState extends State<MistakeNotebookView> {
  bool isLoading = true;
  List<dynamic> notebook = [];

  @override
  void initState() {
    super.initState();
    _loadNotebook();
  }

  void _loadNotebook() async {
    setState(() => isLoading = true);
    try {
      final res = await ApiService.get('/v1/notebook');
      setState(() {
        notebook = res['notebook'] ?? [];
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  void _markAsMastered(int id) async {
    try {
      await ApiService.put('/v1/notebook/$id/master', {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Question marked as Mastered! 🎉'), backgroundColor: AppConstants.accentEmerald),
      );
      _loadNotebook();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryDark,
      appBar: AppBar(
        backgroundColor: AppConstants.scaffoldDark,
        title: const Text('Mistake Notebook', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HERO BANNER CARD
              ExamVerseCard(
                gradient: AppConstants.darkCardGradient,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppConstants.accentRose.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.auto_fix_high, color: AppConstants.accentRose, size: 28),
                    ),
                    const SizedBox(width: AppConstants.space16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Smart Error Revision Engine', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                          SizedBox(height: 2),
                          Text('Review incorrectly answered questions to eliminate weak concepts.', style: TextStyle(color: AppConstants.textSecondary, fontSize: 11.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.space20),

              // SECTION HEADER
              SectionHeader(title: 'Weak Questions Log (${notebook.length})'),
              const SizedBox(height: AppConstants.space12),

              // MISTAKES LIST
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppConstants.accentCyan))
                    : notebook.isEmpty
                        ? const EmptyStateWidget(icon: Icons.check_circle_outline, title: 'No Weak Questions', description: 'Great job! You have no pending mistake questions in your log.')
                        : ListView.separated(
                            itemCount: notebook.length,
                            separatorBuilder: (_, __) => const SizedBox(height: AppConstants.space16),
                            itemBuilder: (context, i) {
                              final item = notebook[i];
                              final isMastered = (item['is_mastered'] ?? 0) == 1;

                              return ExamVerseCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(color: AppConstants.accentCyan.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                                          child: Text('${item['subject_name'] ?? 'General'} • ${item['chapter_name'] ?? 'Topic'}', style: const TextStyle(color: AppConstants.accentCyan, fontSize: 10.5, fontWeight: FontWeight.bold)),
                                        ),
                                        if (isMastered)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(color: AppConstants.accentEmerald.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                                            child: const Text('MASTERED ✓', style: TextStyle(color: AppConstants.accentEmerald, fontSize: 10.5, fontWeight: FontWeight.bold)),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: AppConstants.space12),

                                    Text(item['question_text'] ?? 'Question', style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.bold, height: 1.3)),
                                    const SizedBox(height: AppConstants.space12),

                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(color: AppConstants.accentRose.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                            child: Text('Your Ans: ${item['user_answer'] ?? 'N/A'}', style: const TextStyle(color: AppConstants.accentRose, fontSize: 12, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(color: AppConstants.accentEmerald.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                            child: Text('Correct Ans: ${item['correct_answer'] ?? 'N/A'}', style: const TextStyle(color: AppConstants.accentEmerald, fontSize: 12, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppConstants.space12),

                                    if (item['explanation'] != null && item['explanation'].toString().isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(color: AppConstants.surfaceElevated, borderRadius: BorderRadius.circular(8)),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Explanation / Concept:', style: TextStyle(color: AppConstants.accentCyan, fontSize: 11, fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 2),
                                            Text(item['explanation'], style: const TextStyle(color: AppConstants.textSecondary, fontSize: 11.5, height: 1.3)),
                                          ],
                                        ),
                                      ),
                                    const SizedBox(height: AppConstants.space12),

                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (!isMastered)
                                          SecondaryButton(
                                            label: 'Mark as Mastered ✓',
                                            color: AppConstants.accentEmerald,
                                            onPressed: () => _markAsMastered(item['id']),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
