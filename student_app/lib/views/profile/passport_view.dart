import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';

class PassportView extends StatefulWidget {
  const PassportView({super.key});

  @override
  State<PassportView> createState() => _PassportViewState();
}

class _PassportViewState extends State<PassportView> {
  bool isLoading = true;
  Map<String, dynamic>? passportData;

  @override
  void initState() {
    super.initState();
    _loadPassport();
  }

  void _loadPassport() async {
    try {
      final res = await ApiService.get('/v1/passport');
      setState(() {
        passportData = res;
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

    final holderName = passportData?['passport_holder'] ?? 'Candidate';
    final passportId = passportData?['passport_id'] ?? 'EXAMVERSE-PASS-000001';
    final entries = passportData?['entries'] as List? ?? [];

    return Scaffold(
      backgroundColor: AppConstants.primaryDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Preparation Passport & Profile', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Unified Verified Performance Credentials across Preparation, Ranking & Career', style: TextStyle(color: AppConstants.textSecondary, fontSize: 12)),
              const SizedBox(height: 20),

              // Passport Credential Card (SRD PASS-001/002/003)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppConstants.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: AppConstants.accentIndigo.withOpacity(0.3), blurRadius: 15)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('EXAMVERSE PASSPORT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                          child: const Text('VERIFIED', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(holderName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(passportId, style: const TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text('Verified Exam Readiness Entries', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: entries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final entry = entries[i];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppConstants.cardDark, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppConstants.cardBorder)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry['exam_title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text('AIR Rank: ${entry['central_rank'] != null ? '#${entry['central_rank']}' : 'Unranked'} • State Rank: ${entry['state_rank'] != null ? '#${entry['state_rank']}' : 'N/A'}', style: const TextStyle(color: AppConstants.textSecondary, fontSize: 11)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${entry['best_score']} Mks', style: const TextStyle(color: AppConstants.accentEmerald, fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 2),
                            Text('${entry['accuracy']}% Acc', style: const TextStyle(color: AppConstants.textMuted, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
