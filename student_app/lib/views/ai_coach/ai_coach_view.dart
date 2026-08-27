import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import '../../widgets/premium_cards.dart';
import '../../widgets/skeleton_loader.dart';

class AiCoachView extends StatefulWidget {
  const AiCoachView({super.key});

  @override
  State<AiCoachView> createState() => _AiCoachViewState();
}

class _AiCoachViewState extends State<AiCoachView> {
  bool isLoading = true;
  Map<String, dynamic>? twin;
  Map<String, dynamic>? mission;
  List<dynamic> simulatedStrategies = [];

  @override
  void initState() {
    super.initState();
    _loadAiData();
  }

  void _loadAiData() async {
    try {
      final twinRes = await ApiService.get('/v1/ai/exam-twin/1');
      final missionRes = await ApiService.get('/v1/ai/daily-mission');
      setState(() {
        twin = twinRes;
        mission = missionRes;
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  void _runStrategySimulator() async {
    try {
      final res = await ApiService.post('/v1/ai/strategy-simulations', {});
      setState(() {
        simulatedStrategies = res['simulated_strategies'] ?? [];
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: AppConstants.primaryDark,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.space20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonCard(height: 50, borderRadius: 12),
                SizedBox(height: 20),
                SkeletonCard(height: 240, borderRadius: 24),
                SizedBox(height: 20),
                SkeletonCard(height: 180, borderRadius: 20),
                SizedBox(height: 20),
                Expanded(child: SkeletonListLoader(count: 2, itemHeight: 100)),
              ],
            ),
          ),
        ),
      );
    }

    final readiness = double.parse((twin?['overall_readiness'] ?? 74.0).toString());
    final kScore = double.parse((twin?['knowledge_score'] ?? 74.0).toString());
    final accScore = double.parse((twin?['accuracy_score'] ?? 81.0).toString());
    final spScore = double.parse((twin?['speed_score'] ?? 68.0).toString());
    final csScore = double.parse((twin?['consistency_score'] ?? 64.0).toString());
    final revScore = 59.0;
    final stratScore = 71.0;

    return Scaffold(
      backgroundColor: AppConstants.primaryDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.space20,
            AppConstants.space20,
            AppConstants.space20,
            100, // Bottom padding for floating nav bar
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: AppConstants.aiGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: AppConstants.glowShadow(AppConstants.accentPurple),
                        ),
                        child: const Icon(Icons.psychology, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'AI Exam Twin',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Your preparation intelligence',
                            style: TextStyle(color: AppConstants.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppConstants.accentPurple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppConstants.accentPurple.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.auto_awesome, color: AppConstants.accentPurple, size: 13),
                        SizedBox(width: 4),
                        Text('AI ACTIVE', style: TextStyle(color: AppConstants.accentPurple, fontSize: 11, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.space24),

              // 1. Flagship AI Exam Twin Hero Visualization
              Container(
                padding: const EdgeInsets.all(AppConstants.space24),
                decoration: BoxDecoration(
                  gradient: AppConstants.darkCardGradient,
                  borderRadius: BorderRadius.circular(AppConstants.radiusHero),
                  border: Border.all(color: AppConstants.accentPurple.withOpacity(0.5), width: 1.5),
                  boxShadow: AppConstants.glowShadow(AppConstants.accentPurple),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'PREPARATION READINESS GAUGE',
                          style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppConstants.accentEmerald.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('Top 4% Aspirants', style: TextStyle(color: AppConstants.accentEmerald, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.space20),

                    // Central Readiness Score Ring
                    SizedBox(
                      width: 110,
                      height: 110,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 110,
                            height: 110,
                            child: CircularProgressIndicator(
                              value: readiness / 100.0,
                              strokeWidth: 10,
                              backgroundColor: AppConstants.primaryDark,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppConstants.accentPurple),
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${readiness.toStringAsFixed(0)}',
                                style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800, height: 1.0),
                              ),
                              const Text(
                                'Exam Readiness',
                                style: TextStyle(color: AppConstants.textSecondary, fontSize: 10.5, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppConstants.space24),

                    // 6 Surrounding Indicators (Grid 2x3)
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 2.8,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      children: [
                        _indicatorTile('Knowledge Depth', kScore, AppConstants.accentIndigo),
                        _indicatorTile('Accuracy Rate', accScore, AppConstants.accentEmerald),
                        _indicatorTile('Solving Speed', spScore, AppConstants.accentBlue),
                        _indicatorTile('Consistency', csScore, AppConstants.accentAmber),
                        _indicatorTile('Revision Index', revScore, AppConstants.accentPurple),
                        _indicatorTile('Strategy Score', stratScore, AppConstants.accentCyan),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.space24),

              // 2. ✨ AI INSIGHT CARD (Flagship Recommendation)
              AiInsightCard(
                category: 'Your biggest score blocker',
                title: 'Time Management in Quant',
                description: 'You understand 88% of concepts, but solving speed in Data Interpretation is limiting your raw score by ~10 marks.',
                impactMarks: '8–12 Marks',
                onTapFix: _runStrategySimulator,
              ),
              const SizedBox(height: AppConstants.space24),

              // 3. TODAY'S AI MISSION SUMMARY
              const Text('Personalized Preparation Missions', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: AppConstants.space12),
              Container(
                padding: const EdgeInsets.all(AppConstants.space20),
                decoration: BoxDecoration(
                  color: AppConstants.cardDark,
                  borderRadius: BorderRadius.circular(AppConstants.radiusCard),
                  border: Border.all(color: AppConstants.cardBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${mission?['total_planned_minutes'] ?? 47} Mins Planned Today', style: const TextStyle(color: AppConstants.accentPurple, fontWeight: FontWeight.bold, fontSize: 14)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppConstants.primaryDark, borderRadius: BorderRadius.circular(8)),
                          child: const Text('4 Action Blocks', style: TextStyle(color: AppConstants.textMuted, fontSize: 11.5)),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.space16),
                    ...((mission?['items'] as List? ?? []).map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppConstants.primaryDark,
                              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                              border: Border.all(color: AppConstants.cardBorder.withOpacity(0.5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline, color: AppConstants.accentEmerald, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(item['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: AppConstants.accentIndigo.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                  child: Text('${item['duration_minutes']}m', style: const TextStyle(color: AppConstants.accentIndigo, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        ))),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.space24),

              // 4. EXAM STRATEGY SIMULATOR
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Exam Strategy Simulator', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                  Text('AI POWERED', style: TextStyle(color: AppConstants.accentPurple, fontSize: 11, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: AppConstants.space12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _runStrategySimulator,
                  icon: const Icon(Icons.alt_route, size: 18),
                  label: const Text('Simulate Section Sequence & Time Allocation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.cardDark,
                    foregroundColor: AppConstants.accentBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppConstants.accentBlue, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMedium)),
                  ),
                ),
              ),

              if (simulatedStrategies.isNotEmpty) ...[
                const SizedBox(height: AppConstants.space16),
                ...simulatedStrategies.map((strat) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(AppConstants.space16),
                      decoration: BoxDecoration(
                        color: AppConstants.cardDark,
                        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
                        border: Border.all(color: AppConstants.accentBlue.withOpacity(0.5)),
                        boxShadow: AppConstants.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(strat['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 6),
                          Text('Expected Score Band: ${strat['estimated_score_range']}', style: const TextStyle(color: AppConstants.accentEmerald, fontWeight: FontWeight.w800, fontSize: 13)),
                          const SizedBox(height: 6),
                          Text(strat['rationale'] ?? '', style: const TextStyle(color: AppConstants.textSecondary, fontSize: 12.5, height: 1.35)),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _indicatorTile(String label, double val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppConstants.primaryDark.withOpacity(0.8),
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
        border: Border.all(color: AppConstants.cardBorder.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: AppConstants.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
              Text('${val.toStringAsFixed(0)}%', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: val / 100,
              backgroundColor: AppConstants.cardDark,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}
