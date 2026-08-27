class UserRanking {
  final int currentRank;
  final int previousRank;
  final int bestRank;
  final double percentile;
  final int totalQuestionsSolved;
  final int correctAnswers;
  final int incorrectAnswers;
  final double accuracy;
  final int testCount;
  final int streakDays;
  final int xpPoints;

  const UserRanking({
    this.currentRank = 124,
    this.previousRank = 142,
    this.bestRank = 89,
    this.percentile = 96.8,
    this.totalQuestionsSolved = 1248,
    this.correctAnswers = 1018,
    this.incorrectAnswers = 230,
    this.accuracy = 81.6,
    this.testCount = 34,
    this.streakDays = 7,
    this.xpPoints = 1050,
  });

  int get rankImprovement => previousRank - currentRank;
  bool get isRankImproved => rankImprovement > 0;

  int get questionsXp => correctAnswers * 4;
  int get accuracyXp => (accuracy * 3.5).round();
  int get testsXp => testCount * 20;
  int get streakXp => streakDays * 10;
  int get totalCalculatedXp => questionsXp + accuracyXp + testsXp + streakXp;

  factory UserRanking.fromJson(Map<String, dynamic> json) {
    final solved = json['total_questions_solved'] ?? json['questions_solved'] ?? 1248;
    final correct = json['correct_answers'] ?? 1018;
    final incorrect = json['incorrect_answers'] ?? (solved - correct);
    final acc = double.tryParse((json['accuracy'] ?? json['accuracy_percentage'] ?? 81.6).toString()) ?? 81.6;

    return UserRanking(
      currentRank: json['current_rank'] ?? json['rank'] ?? 124,
      previousRank: json['previous_rank'] ?? 142,
      bestRank: json['best_rank'] ?? 89,
      percentile: double.tryParse((json['percentile'] ?? 96.8).toString()) ?? 96.8,
      totalQuestionsSolved: solved,
      correctAnswers: correct,
      incorrectAnswers: incorrect,
      accuracy: acc,
      testCount: json['tests_attempted'] ?? json['test_count'] ?? 34,
      streakDays: json['streak_days'] ?? json['streak'] ?? 7,
      xpPoints: json['xp_points'] ?? json['xp'] ?? 1050,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_rank': currentRank,
      'previous_rank': previousRank,
      'best_rank': bestRank,
      'percentile': percentile,
      'total_questions_solved': totalQuestionsSolved,
      'correct_answers': correctAnswers,
      'incorrect_answers': incorrectAnswers,
      'accuracy': accuracy,
      'test_count': testCount,
      'streak_days': streakDays,
      'xp_points': xpPoints,
    };
  }
}
