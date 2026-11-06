import 'package:flutter_test/flutter_test.dart';
import 'package:student_app/models/ranking_model.dart';

/// Both the home screen and the passport used to render
/// "↑ ${rankImprovement} positions this week", which printed "↑ -3 positions"
/// when the candidate had actually slipped, claimed a weekly comparison it was
/// not making, and reported movement against a previous rank of zero.
void main() {
  group('UserRanking.rankMovementLabel', () {
    test('says nothing was tracked when there is no earlier ranked test', () {
      const r = UserRanking(currentRank: 4, previousRank: 0, testCount: 1);
      expect(r.rankMovementLabel, contains('Attempt another test'));
      expect(r.rankMovementLabel, isNot(contains('↑')));
      expect(r.rankMovementLabel, isNot(contains('↓')));
    });

    test('says nothing was tracked when the candidate is unranked', () {
      const r = UserRanking(currentRank: 0, previousRank: 5);
      expect(r.rankMovementLabel, contains('Attempt another test'));
    });

    test('reports a gain with an up arrow', () {
      const r = UserRanking(currentRank: 2, previousRank: 7);
      expect(r.rankMovementLabel, '↑ 5 places since your last test');
    });

    test('reports a drop as a drop, never as a negative gain', () {
      const r = UserRanking(currentRank: 9, previousRank: 4);
      final label = r.rankMovementLabel;
      expect(label, '↓ 5 places since your last test');
      expect(label, isNot(contains('-')));
      expect(label, isNot(contains('↑')));
    });

    test('says steady when the rank has not moved', () {
      const r = UserRanking(currentRank: 3, previousRank: 3);
      expect(r.rankMovementLabel, 'Holding steady since your last test');
    });

    test('uses the singular for a one-place move', () {
      expect(const UserRanking(currentRank: 1, previousRank: 2).rankMovementLabel,
          '↑ 1 place since your last test');
      expect(const UserRanking(currentRank: 3, previousRank: 2).rankMovementLabel,
          '↓ 1 place since your last test');
    });

    test('never claims a weekly comparison it is not making', () {
      const r = UserRanking(currentRank: 2, previousRank: 7);
      expect(r.rankMovementLabel.toLowerCase(), isNot(contains('this week')));
    });
  });

  group('UserRanking parsing', () {
    test('a candidate with no attempts carries no fabricated figures', () {
      final r = UserRanking.fromJson(const {
        'current_rank': 0,
        'previous_rank': 0,
        'best_rank': 0,
        'percentile': 0,
        'streak_days': 0,
        'test_count': 0,
      });
      expect(r.hasData, isFalse);
      expect(r.streakDays, 0);
      expect(r.percentile, 0);
      expect(r.bestRank, 0);
    });
  });
}
