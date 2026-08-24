import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import '../../models/exam_models.dart';
import '../current_affairs/current_affairs_view.dart';
import '../current_affairs/current_affairs_article_view.dart';

class HomeView extends StatefulWidget {
  final Function(int examId) onSelectExam;
  final Function(int testId) onSelectTest;
  final VoidCallback onOpenAiCoach;
  final VoidCallback onOpenLeaderboard;

  const HomeView({
    super.key,
    required this.onSelectExam,
    required this.onSelectTest,
    required this.onOpenAiCoach,
    required this.onOpenLeaderboard,
  });

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool isLoading = true;
  List<ExamCategory> categories = [];
  List<ExamItem> featuredExams = [];
  Map<String, dynamic>? monthlyChallenge;
  List<dynamic> currentAffairs = [];
  List<dynamic> jobAlerts = [];
  Map<String, dynamic>? topper;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  void _loadHomeData() async {
    try {
      final res = await ApiService.get('/v1/home');
      setState(() {
        categories = (res['categories'] as List? ?? []).map((c) => ExamCategory.fromJson(c)).toList();
        featuredExams = (res['featured_exams'] as List? ?? []).map((e) => ExamItem.fromJson(e)).toList();
        monthlyChallenge = res['monthly_challenge'];
        currentAffairs = res['current_affairs'] ?? [];
        jobAlerts = res['job_alerts'] ?? [];
        topper = res['featured_topper'];
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppConstants.accentBlue));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Welcome Back, Candidate!', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppConstants.accentBlue.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                        child: const Text('PRACTICE -> COMPETE -> DIAGNOSE', style: TextStyle(color: AppConstants.accentBlue, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
              CircleAvatar(
                backgroundColor: AppConstants.cardDark,
                child: IconButton(
                  icon: const Icon(Icons.notifications_none, color: Colors.white),
                  onPressed: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Flagship Monthly National Challenge Callout Banner (SRD CHAL-001)
          if (monthlyChallenge != null)
            GestureDetector(
              onTap: () => widget.onSelectTest(monthlyChallenge!['test_id']),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppConstants.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: AppConstants.accentIndigo.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
                            child: const Text('MONTHLY NATIONAL CHALLENGE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 8),
                          Text(monthlyChallenge!['title'] ?? 'National Flagship Mock', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          const Text('Compete for All-India Central AIR Rank & State Rank with AI Twin Diagnosis.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => widget.onSelectTest(monthlyChallenge!['test_id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppConstants.primaryDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Attempt Now', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),

          // Today's AI Mission Widget (SRD AIM-001)
          GestureDetector(
            onTap: widget.onOpenAiCoach,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConstants.cardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppConstants.accentEmerald.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: AppConstants.accentEmerald.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.auto_awesome, color: AppConstants.accentEmerald),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Today\'s AI Preparation Mission', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        SizedBox(height: 2),
                        Text('47 Mins planned • Weak Topic: Quant Percentage', style: TextStyle(color: AppConstants.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: AppConstants.textMuted, size: 14),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Category Discovery Cards
          const Text('Exam Discovery & Ecosystem', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final cat = categories[i];
                return Container(
                  width: 140,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppConstants.cardDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppConstants.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(_getCategoryIcon(cat.type), color: AppConstants.accentBlue, size: 24),
                      Text(cat.name, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                );
              },
            ),
          ),
          // Daily Current Affairs Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.newspaper_outlined, size: 20, color: AppConstants.accentBlue),
                  SizedBox(width: 8),
                  Text('Daily Current Affairs & AI Quiz', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CurrentAffairsView()),
                  );
                },
                child: const Text('View All', style: TextStyle(color: AppConstants.accentBlue, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (currentAffairs.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: currentAffairs.length > 3 ? 3 : currentAffairs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final ca = currentAffairs[i];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CurrentAffairsArticleView(articleId: ca['id']),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppConstants.cardDark,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppConstants.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366f1).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.auto_awesome, color: Color(0xFF818cf8), size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(ca['category'] ?? 'General', style: const TextStyle(color: Color(0xFF818cf8), fontSize: 10.5, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 6),
                                  Text('· ${ca['publish_date'] ?? ''}', style: const TextStyle(color: AppConstants.textMuted, fontSize: 10)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ca['title'] ?? '',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366f1).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('AI Quiz', style: TextStyle(color: Color(0xFF818cf8), fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 28),

          // Featured Target Exams
          const Text('Popular Competitive Exams', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: featuredExams.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final exam = featuredExams[i];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppConstants.cardDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppConstants.cardBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(color: AppConstants.primaryDark, borderRadius: BorderRadius.circular(10)),
                      child: Center(child: Text(exam.orgName ?? 'EXAM', style: const TextStyle(color: AppConstants.accentBlue, fontWeight: FontWeight.bold, fontSize: 12))),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(exam.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text(exam.shortDescription ?? '', style: const TextStyle(color: AppConstants.textSecondary, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward, color: AppConstants.accentBlue),
                      onPressed: () => widget.onSelectExam(exam.id),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String type) {
    switch (type) {
      case 'government': return Icons.account_balance;
      case 'entrance': return Icons.school;
      case 'private_job': return Icons.work;
      case 'upskilling': return Icons.psychology;
      default: return Icons.explore;
    }
  }
}
