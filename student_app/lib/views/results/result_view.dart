import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import '../../widgets/premium_cards.dart';
import '../../widgets/skeleton_loader.dart';

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
      return Scaffold(
        backgroundColor: AppConstants.primaryDark,
        appBar: AppBar(
          backgroundColor: AppConstants.cardDark,
          title: const Text('Result Analysis', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          leading: IconButton(icon: const Icon(Icons.home, color: Colors.white), onPressed: widget.onHome),
        ),
        body: const Padding(
          padding: EdgeInsets.all(AppConstants.space20),
          child: SkeletonListLoader(count: 3, itemHeight: 120),
        ),
      );
    }

    final score = double.parse((summary?['score'] ?? 154.0).toString());
    final accuracy = double.parse((summary?['accuracy_percentage'] ?? 82.0).toString());
    final centralRank = summary?['central_rank'] ?? 4821;
    final stateRank = summary?['state_rank'] ?? 312;
    final percentile = double.parse((summary?['percentile'] ?? 96.4).toString());
    final testTitle = summary?['test_title'] ?? 'Full Length National Mock';

    return Scaffold(
      backgroundColor: AppConstants.primaryDark,
      appBar: AppBar(
        backgroundColor: AppConstants.cardDark,
        elevation: 0,
        title: Text(testTitle, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.home, color: Colors.white), onPressed: widget.onHome),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score & Rank Hero Card
            Container(
              padding: const EdgeInsets.all(AppConstants.space24),
              decoration: BoxDecoration(
                gradient: AppConstants.readinessGradient,
                borderRadius: BorderRadius.circular(AppConstants.radiusHero),
                boxShadow: AppConstants.glowShadow(AppConstants.accentIndigo),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TEST PERFORMANCE SUMMARY', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                        child: const Text('↑ 12 marks from last mock', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.space16),
                  Text('${score.toStringAsFixed(1)} / 200', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text('Total Score Achieved', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                  const SizedBox(height: AppConstants.space20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _heroBadge('AIR Rank', '#$centralRank'),
                      _heroBadge('State Rank', '#$stateRank'),
                      _heroBadge('Percentile', '${percentile.toStringAsFixed(1)}%'),
                      _heroBadge('Accuracy', '${accuracy.toStringAsFixed(1)}%'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.space24),

            // Impactful Lost Marks Card Component
            LostMarksCard(
              totalLost: 40,
              onTapCreatePlan: widget.onHome,
            ),
            const SizedBox(height: AppConstants.space24),

            // Sectional Breakdown Table (SRD AN-001)
            const Text('Sectional Performance Breakdown', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppConstants.space12),
            Container(
              decoration: BoxDecoration(
                color: AppConstants.cardDark,
                borderRadius: BorderRadius.circular(AppConstants.radiusCard),
                border: Border.all(color: AppConstants.cardBorder),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sections.length,
                separatorBuilder: (_, __) => const Divider(color: AppConstants.cardBorder, height: 1),
                itemBuilder: (context, i) {
                  final sec = sections[i];
                  return Padding(
                    padding: const EdgeInsets.all(AppConstants.space16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(sec['section_name'] ?? 'Section', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.5)),
                            const SizedBox(height: 4),
                            Text('Correct: ${sec['correct']} • Wrong: ${sec['wrong']} • Unattempted: ${sec['unattempted']}', style: const TextStyle(color: AppConstants.textSecondary, fontSize: 11.5)),
                          ],
                        ),
                        Text('${double.parse(sec['section_score'].toString()).toStringAsFixed(1)} Mks', style: const TextStyle(color: AppConstants.accentBlue, fontWeight: FontWeight.w800, fontSize: 14.5)),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppConstants.space24),

            // Solutions Toggle Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => setState(() => showSolutions = !showSolutions),
                icon: Icon(showSolutions ? Icons.visibility_off : Icons.lightbulb, size: 18),
                label: Text(showSolutions ? 'Hide Question Solutions' : 'View Step-by-Step Solutions & AI Shortcuts', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.cardDark,
                  foregroundColor: AppConstants.accentBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppConstants.accentBlue, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMedium)),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.space16),

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
                    padding: const EdgeInsets.all(AppConstants.space16),
                    decoration: BoxDecoration(
                      color: AppConstants.cardDark,
                      borderRadius: BorderRadius.circular(AppConstants.radiusCard),
                      border: Border.all(color: isCorr ? AppConstants.accentEmerald : AppConstants.accentRose.withOpacity(0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Q${sol['question_order']}.', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: isCorr ? AppConstants.accentEmerald.withOpacity(0.2) : AppConstants.accentRose.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                              child: Text(isCorr ? 'CORRECT (+${sol['positive_marks']})' : 'WRONG (-${sol['negative_marks']})', style: TextStyle(color: isCorr ? AppConstants.accentEmerald : AppConstants.accentRose, fontSize: 10.5, fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(sol['question_text'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.35)),
                        const SizedBox(height: 12),

                        // Solution Explanation
                        if (sol['solution_text'] != null) ...[
                          const Text('Solution Explanation:', style: TextStyle(color: AppConstants.textSecondary, fontSize: 11.5, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(sol['solution_text'], style: const TextStyle(color: AppConstants.accentBlue, fontSize: 12.5, height: 1.4)),
                        ],

                        // Shortcut Method (SRD SOL-002)
                        if (sol['shortcut_text'] != null && sol['shortcut_text'].toString().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: AppConstants.accentAmber.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              children: [
                                const Icon(Icons.bolt, color: AppConstants.accentAmber, size: 16),
                                const SizedBox(width: 6),
                                Expanded(child: Text('Shortcut: ${sol['shortcut_text']}', style: const TextStyle(color: AppConstants.accentAmber, fontSize: 11.5, fontWeight: FontWeight.bold))),
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
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10.5)),
      ],
    );
  }
}
