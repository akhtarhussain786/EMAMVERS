import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';

class ResultView extends StatefulWidget {
  final int attemptId;
  final VoidCallback onHome;

  const ResultView({super.key, required this.attemptId, required this.onHome});

  @override
  State<ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<ResultView> {
  bool isLoading = true;
  Map<String, dynamic>? summary;
  List<dynamic> sections = [];
  List<dynamic> solutions = [];
  bool showSolutions = false;

  @override
  void initState() {
    super.initState();
    _loadResult();
  }

  void _loadResult() async {
    try {
      final res = await ApiService.get('/v1/attempts/${widget.attemptId}/result');
      final solRes = await ApiService.get('/v1/attempts/${widget.attemptId}/solutions');
      setState(() {
        summary = res['summary'];
        sections = res['section_breakdown'] ?? [];
        solutions = solRes ?? [];
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

    final score = double.parse((summary?['score'] ?? 0).toString());
    final accuracy = double.parse((summary?['accuracy_percentage'] ?? 0).toString());
    final centralRank = summary?['central_rank'] ?? 1;
    final stateRank = summary?['state_rank'] ?? 1;
    final percentile = double.parse((summary?['percentile'] ?? 0).toString());
    final testTitle = summary?['test_title'] ?? 'Test Result';

    return Scaffold(
      backgroundColor: AppConstants.primaryDark,
      appBar: AppBar(
        backgroundColor: AppConstants.cardDark,
        title: Text(testTitle, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.home, color: Colors.white), onPressed: widget.onHome),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score & Rank Hero Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppConstants.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: AppConstants.accentIndigo.withOpacity(0.3), blurRadius: 15)],
              ),
              child: Column(
                children: [
                  const Text('YOUR TOTAL SCORE', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${score.toStringAsFixed(2)} Marks', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _heroBadge('Central AIR Rank', '#$centralRank'),
                      _heroBadge('State Rank', '#$stateRank'),
                      _heroBadge('Percentile', '${percentile.toStringAsFixed(1)}%'),
                      _heroBadge('Accuracy', '${accuracy.toStringAsFixed(1)}%'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Sectional Breakdown Table (SRD AN-001)
            const Text('Sectional Performance Analysis', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(color: AppConstants.cardDark, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppConstants.cardBorder)),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sections.length,
                separatorBuilder: (_, __) => const Divider(color: AppConstants.cardBorder, height: 1),
                itemBuilder: (context, i) {
                  final sec = sections[i];
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(sec['section_name'] ?? 'Section', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text('Correct: ${sec['correct']} • Wrong: ${sec['wrong']} • Unattempted: ${sec['unattempted']}', style: const TextStyle(color: AppConstants.textSecondary, fontSize: 11)),
                          ],
                        ),
                        Text('${double.parse(sec['section_score'].toString()).toStringAsFixed(1)} Mks', style: const TextStyle(color: AppConstants.accentBlue, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Solutions Toggle Button
            ElevatedButton(
              onPressed: () => setState(() => showSolutions = !showSolutions),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.cardDark,
                foregroundColor: AppConstants.accentBlue,
                minimumSize: const Size(double.infinity, 48),
                side: const BorderSide(color: AppConstants.accentBlue),
              ),
              child: Text(showSolutions ? 'Hide Question Solutions' : 'View Step-by-Step Solutions & Shortcuts', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),

            // Solutions List (SRD SOL-001/002)
            if (showSolutions)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: solutions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, i) {
                  final sol = solutions[i];
                  final isCorr = sol['is_correct'] == 1;
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppConstants.cardDark, borderRadius: BorderRadius.circular(14), border: Border.all(color: isCorr ? AppConstants.accentEmerald : Colors.redAccent.withOpacity(0.5))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Q${sol['question_order']}.', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: isCorr ? AppConstants.accentEmerald.withOpacity(0.2) : Colors.redAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                              child: Text(isCorr ? 'CORRECT (+${sol['positive_marks']})' : 'WRONG (-${sol['negative_marks']})', style: TextStyle(color: isCorr ? AppConstants.accentEmerald : Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(sol['question_text'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14)),
                        const SizedBox(height: 12),

                        // Solution Explanation
                        if (sol['solution_text'] != null) ...[
                          const Text('Solution Explanation:', style: TextStyle(color: AppConstants.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(sol['solution_text'], style: const TextStyle(color: AppConstants.accentBlue, fontSize: 12, height: 1.4)),
                        ],

                        // Shortcut Method (SRD SOL-002)
                        if (sol['shortcut_text'] != null && sol['shortcut_text'].toString().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: AppConstants.accentAmber.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              children: [
                                const Icon(Icons.bolt, color: AppConstants.accentAmber, size: 16),
                                const SizedBox(width: 6),
                                Expanded(child: Text('Shortcut: ${sol['shortcut_text']}', style: const TextStyle(color: AppConstants.accentAmber, fontSize: 11, fontWeight: FontWeight.bold))),
                              ],
                            ),
                          ),
                        ],
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

  Widget _heroBadge(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }
}
