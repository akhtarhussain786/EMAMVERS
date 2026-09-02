import 'package:flutter/material.dart';
import '../core/constants.dart';

/// 1. YOUR EXAM READINESS HERO CARD
class ReadinessCard extends StatelessWidget {
  final int score;
  final String statusText;
  final String monthlyChange;
  final VoidCallback onTapAiTwin;

  const ReadinessCard({
    super.key,
    this.score = 72,
    this.statusText = 'Moderate Readiness',
    this.monthlyChange = '+6% this month',
    required this.onTapAiTwin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.space24),
      decoration: BoxDecoration(
        gradient: AppConstants.readinessGradient,
        borderRadius: BorderRadius.circular(AppConstants.radiusHero),
        boxShadow: AppConstants.glowShadow(AppConstants.accentIndigo),
      ),
      child: Stack(
        children: [
          // Background decorative glow circle
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.auto_awesome, color: AppConstants.accentBlue, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'YOUR EXAM READINESS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppConstants.accentEmerald.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      monthlyChange,
                      style: const TextStyle(
                        color: AppConstants.accentEmerald,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.space20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Animated Progress Ring Visualization
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: score / 100.0,
                            strokeWidth: 8,
                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$score',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                height: 1.0,
                              ),
                            ),
                            const Text(
                              '/100',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppConstants.space20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'AI prediction based on your last 8 mock tests & speed stats.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12.5,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.space20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onTapAiTwin,
                  icon: const Icon(Icons.psychology, size: 18),
                  label: const Text('View AI Exam Twin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppConstants.primaryDark,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMedium)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 2. TODAY'S AI MISSION CARD
class AiMissionCard extends StatelessWidget {
  final int completedCount;
  final int totalCount;
  final VoidCallback onTapMission;

  const AiMissionCard({
    super.key,
    this.completedCount = 2,
    this.totalCount = 5,
    required this.onTapMission,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = completedCount / totalCount;

    return Container(
      padding: const EdgeInsets.all(AppConstants.space20),
      decoration: BoxDecoration(
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(color: AppConstants.accentPurple.withValues(alpha: 0.4), width: 1.2),
        boxShadow: AppConstants.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppConstants.accentPurple.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome, color: AppConstants.accentPurple, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        '✨ Today\'s AI Mission',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Personalized from your latest performance',
                        style: TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                '$completedCount of $totalCount completed',
                style: const TextStyle(
                  color: AppConstants.accentPurple,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.space16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: AppConstants.primaryDark,
              valueColor: const AlwaysStoppedAnimation<Color>(AppConstants.accentPurple),
            ),
          ),
          const SizedBox(height: AppConstants.space16),

          // Task Items
          _buildTaskItem(
            title: 'Percentage Practice',
            subtitle: '12 min • Weak Topic',
            isCompleted: true,
            onTap: onTapMission,
          ),
          const SizedBox(height: 10),
          _buildTaskItem(
            title: 'Current Affairs Daily Quiz',
            subtitle: '5 min • 10 Questions',
            isCompleted: true,
            onTap: onTapMission,
          ),
          const SizedBox(height: 10),
          _buildTaskItem(
            title: 'Reasoning Syllogism Drill',
            subtitle: '15 min • High Weightage',
            isCompleted: false,
            onTap: onTapMission,
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem({
    required String title,
    required String subtitle,
    required bool isCompleted,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppConstants.primaryDark.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          border: Border.all(
            color: isCompleted ? AppConstants.accentEmerald.withValues(alpha: 0.3) : AppConstants.cardBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isCompleted ? AppConstants.accentEmerald : AppConstants.textMuted,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isCompleted ? AppConstants.textSecondary : Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isCompleted ? AppConstants.textMuted : AppConstants.accentPurple,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

/// 3. AI INSIGHT CARD
class AiInsightCard extends StatelessWidget {
  final String category;
  final String title;
  final String description;
  final String impactMarks;
  final VoidCallback onTapFix;

  const AiInsightCard({
    super.key,
    this.category = 'Your biggest score blocker',
    this.title = 'Time Management in Quant',
    this.description = 'You understand most concepts, but your solving speed is currently limiting your score.',
    this.impactMarks = '8–12 Marks',
    required this.onTapFix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.space20),
      decoration: BoxDecoration(
        gradient: AppConstants.darkCardGradient,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(color: AppConstants.accentPurple.withValues(alpha: 0.5), width: 1.2),
        boxShadow: AppConstants.glowShadow(AppConstants.accentPurple),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppConstants.accentPurple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: AppConstants.accentPurple, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      category.toUpperCase(),
                      style: const TextStyle(
                        color: AppConstants.accentPurple,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.space12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              color: AppConstants.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppConstants.space16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppConstants.primaryDark,
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              border: Border.all(color: AppConstants.cardBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ESTIMATED IMPACT',
                      style: TextStyle(color: AppConstants.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '+$impactMarks',
                      style: const TextStyle(color: AppConstants.accentEmerald, fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: onTapFix,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.accentPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Fix This Weakness →', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 4. COMPACT METRIC TILE
class MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String trend;
  final IconData icon;
  final Color color;

  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.trend,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.space16),
      decoration: BoxDecoration(
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(color: AppConstants.cardBorder),
        boxShadow: AppConstants.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppConstants.accentEmerald.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  trend,
                  style: const TextStyle(color: AppConstants.accentEmerald, fontSize: 10.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.space12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppConstants.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// 5. NATIONAL CHALLENGE HERO CARD
class NationalChallengeCard extends StatelessWidget {
  final String title;
  final String participants;
  final VoidCallback onTapJoin;

  const NationalChallengeCard({
    super.key,
    this.title = 'August National Flagship Mock',
    this.participants = '128K+ Aspirants',
    required this.onTapJoin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.space20),
      decoration: BoxDecoration(
        gradient: AppConstants.goldGradient,
        borderRadius: BorderRadius.circular(AppConstants.radiusHero),
        boxShadow: AppConstants.glowShadow(AppConstants.accentAmber),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.emoji_events, color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Text('LIVE NATIONAL CHALLENGE', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(participants, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.space12),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Compete for All-India AIR Rank & State Rank with AI Twin Diagnosis.',
            style: TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
          const SizedBox(height: AppConstants.space16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTapJoin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppConstants.primaryDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMedium)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Join Challenge Now →', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
            ),
          ),
        ],
      ),
    );
  }
}

/// 6. PREMIUM TEST ITEM CARD
class TestCard extends StatelessWidget {
  final String title;
  final String category;
  final int totalQuestions;
  final int totalMarks;
  final int durationMinutes;
  final int totalAttempts;
  final String difficulty;
  final bool isFree;
  final VoidCallback onTapStart;

  const TestCard({
    super.key,
    required this.title,
    required this.category,
    required this.totalQuestions,
    required this.totalMarks,
    required this.durationMinutes,
    required this.totalAttempts,
    this.difficulty = 'Medium',
    this.isFree = true,
    required this.onTapStart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.space16),
      decoration: BoxDecoration(
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(color: AppConstants.cardBorder),
        boxShadow: AppConstants.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppConstants.accentBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category.toUpperCase(),
                  style: const TextStyle(color: AppConstants.accentBlue, fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isFree ? AppConstants.accentEmerald.withValues(alpha: 0.2) : AppConstants.accentAmber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isFree ? 'FREE MOCK' : 'PREMIUM',
                  style: TextStyle(
                    color: isFree ? AppConstants.accentEmerald : AppConstants.accentAmber,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildBadge(Icons.help_outline, '$totalQuestions Qs'),
              const SizedBox(width: 12),
              _buildBadge(Icons.timer_outlined, '$durationMinutes mins'),
              const SizedBox(width: 12),
              _buildBadge(Icons.stars_outlined, '$totalMarks Marks'),
              const SizedBox(width: 12),
              _buildBadge(Icons.people_outline, '$totalAttempts Attempts'),
            ],
          ),
          const SizedBox(height: AppConstants.space16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Difficulty: $difficulty',
                style: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5),
              ),
              ElevatedButton(
                onPressed: onTapStart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.accentIndigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                child: const Text('Start Test →', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppConstants.textSecondary),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: AppConstants.textSecondary, fontSize: 11.5)),
      ],
    );
  }
}

/// 7. LOST MARKS BREAKDOWN CARD
class LostMarksCard extends StatelessWidget {
  final int totalLost;
  final VoidCallback onTapCreatePlan;

  const LostMarksCard({
    super.key,
    this.totalLost = 40,
    required this.onTapCreatePlan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.space20),
      decoration: BoxDecoration(
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(color: AppConstants.accentRose.withValues(alpha: 0.4), width: 1.2),
        boxShadow: AppConstants.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'You lost approximately',
                style: TextStyle(color: AppConstants.textSecondary, fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppConstants.accentRose.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$totalLost Marks',
                  style: const TextStyle(color: AppConstants.accentRose, fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.space16),
          const Text('Lost Marks Breakdown:', style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildItem('Concept Gap', 12, AppConstants.accentRose),
          _buildItem('Silly Mistakes', 8, AppConstants.accentAmber),
          _buildItem('Time Pressure', 10, AppConstants.accentPurple),
          _buildItem('Guessing', 6, AppConstants.accentBlue),
          _buildItem('Question Selection', 4, AppConstants.accentEmerald),
          const SizedBox(height: AppConstants.space16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppConstants.primaryDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppConstants.accentEmerald.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '18–24 Marks Potentially Recoverable',
                  style: TextStyle(color: AppConstants.accentEmerald, fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: onTapCreatePlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.accentEmerald,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Create Plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(String label, int marks, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12.5))),
          Text('$marks Marks', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
        ],
      ),
    );
  }
}
