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
    this.currentRank = 0,
    this.previousRank = 0,
    this.bestRank = 0,
    this.percentile = 0,
    this.totalQuestionsSolved = 0,
    this.correctAnswers = 0,
    this.incorrectAnswers = 0,
    this.accuracy = 0,
    this.testCount = 0,
    this.streakDays = 0,
    this.xpPoints = 0,
  });

  /// True when the candidate has no evaluated attempts yet, so screens can show
  /// an empty state instead of a row of zeros pretending to be a ranking.
  bool get hasData => testCount > 0 || totalQuestionsSolved > 0;

  int get rankImprovement => previousRank - currentRank;
  bool get isRankImproved => rankImprovement > 0;

  int get questionsXp => correctAnswers * 4;
  int get accuracyXp => (accuracy * 3.5).round();
  int get testsXp => testCount * 20;
  int get streakXp => streakDays * 10;
  int get totalCalculatedXp => questionsXp + accuracyXp + testsXp + streakXp;

  factory UserRanking.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) => v == null ? 0 : (v is int ? v : int.tryParse(v.toString()) ?? 0);
    double asDouble(dynamic v) => v == null ? 0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0);

    final solved = asInt(json['total_questions_solved'] ?? json['questions_solved']);
    final correct = asInt(json['correct_answers']);
    final incorrect = json['incorrect_answers'] != null
        ? asInt(json['incorrect_answers'])
        : (solved - correct).clamp(0, solved);

    return UserRanking(
      currentRank: asInt(json['current_rank'] ?? json['rank']),
      previousRank: asInt(json['previous_rank']),
      bestRank: asInt(json['best_rank']),
      percentile: asDouble(json['percentile']),
      totalQuestionsSolved: solved,
      correctAnswers: correct,
      incorrectAnswers: incorrect,
      accuracy: asDouble(json['accuracy'] ?? json['accuracy_percentage'] ?? json['overall_accuracy']),
      testCount: asInt(json['tests_attempted'] ?? json['test_count'] ?? json['tests_taken']),
      streakDays: asInt(json['streak_days'] ?? json['streak']),
      xpPoints: asInt(json['xp_points'] ?? json['xp']),
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
