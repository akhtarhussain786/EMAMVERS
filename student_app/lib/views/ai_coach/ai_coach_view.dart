import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';

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
      return const Scaffold(backgroundColor: AppConstants.primaryDark, body: Center(child: CircularProgressIndicator(color: AppConstants.accentBlue)));
    }

    final readiness = double.parse((twin?['overall_readiness'] ?? 74.0).toString());
    final kScore = double.parse((twin?['knowledge_score'] ?? 68.5).toString());
    final accScore = double.parse((twin?['accuracy_score'] ?? 74.0).toString());
    final spScore = double.parse((twin?['speed_score'] ?? 65.0).toString());
    final csScore = double.parse((twin?['consistency_score'] ?? 80.0).toString());

    return Scaffold(
      backgroundColor: AppConstants.primaryDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.auto_awesome, color: AppConstants.accentEmerald, size: 24),
                  SizedBox(width: 8),
                  Text('AI Performance Coach & Twin', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              const Text('Evidence-Based Diagnosis & Personalization Engine', style: TextStyle(color: AppConstants.textSecondary, fontSize: 12)),
              const SizedBox(height: 20),

              // 1. Digital Exam Twin Readiness Profile (SRD AI-001)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppConstants.cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppConstants.accentEmerald.withOpacity(0.5))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('AI Digital Exam Twin Readiness', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppConstants.accentEmerald.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                          child: Text('${readiness.toStringAsFixed(0)} / 100', style: const TextStyle(color: AppConstants.accentEmerald, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _dimensionBar('Knowledge Depth', kScore),
                    _dimensionBar('Accuracy Rate', accScore),
                    _dimensionBar('Speed & Time Allocation', spScore),
                    _dimensionBar('Test Consistency', csScore),
                    const SizedBox(height: 12),
                    Text('Diagnosis: ${twin?['diagnosis_summary'] ?? ''}', style: const TextStyle(color: AppConstants.textSecondary, fontSize: 12, height: 1.4)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. Today's AI Daily Mission (SRD AIM-001/002/003)
              const Text('Today\'s AI Preparation Mission', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppConstants.cardDark, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppConstants.cardBorder)),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${mission?['total_planned_minutes'] ?? 47} Mins Planned', style: const TextStyle(color: AppConstants.accentBlue, fontWeight: FontWeight.bold)),
                        const Text('4 Action Blocks', style: TextStyle(color: AppConstants.textMuted, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...((mission?['items'] as List? ?? []).map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline, color: AppConstants.accentEmerald, size: 18),
                              const SizedBox(width: 10),
                              Expanded(child: Text(item['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13))),
                              Text('${item['duration_minutes']}m', style: const TextStyle(color: AppConstants.textMuted, fontSize: 12)),
                            ],
                          ),
                        ))),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. Exam Strategy Simulator (SRD STRAT-001/002)
              const Text('Exam Strategy Simulator', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _runStrategySimulator,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.cardDark,
                  foregroundColor: AppConstants.accentBlue,
                  minimumSize: const Size(double.infinity, 48),
                  side: const BorderSide(color: AppConstants.accentBlue),
                ),
                child: const Text('Simulate Section Sequence & Time Strategy', style: TextStyle(fontWeight: FontWeight.bold)),
              ),

              if (simulatedStrategies.isNotEmpty) ...[
                const SizedBox(height: 16),
                ...simulatedStrategies.map((strat) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppConstants.cardDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppConstants.accentBlue.withOpacity(0.5))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(strat['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 6),
                          Text('Expected Score Band: ${strat['estimated_score_range']}', style: const TextStyle(color: AppConstants.accentEmerald, fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(strat['rationale'] ?? '', style: const TextStyle(color: AppConstants.textSecondary, fontSize: 12)),
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

  Widget _dimensionBar(String label, double val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Text('${val.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: val / 100, backgroundColor: AppConstants.primaryDark, color: AppConstants.accentEmerald, minHeight: 6),
          ),
        ],
      ),
    );
  }
}
