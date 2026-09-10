import 'package:flutter_test/flutter_test.dart';
import 'package:student_app/models/exam_models.dart';

QuestionItem buildQuestion() => QuestionItem(
      questionId: 11,
      questionOrder: 1,
      positiveMarks: 2,
      negativeMarks: 0.5,
      questionType: 'MCQ',
      translations: const [],
      options: const [],
    );

void main() {
  group('QuestionItem.isAnswered', () {
    test('is false with no response', () {
      expect(buildQuestion().isAnswered, isFalse);
    });

    test('is false for an empty selection', () {
      final q = buildQuestion()..selectedOptionKey = '';
      expect(q.isAnswered, isFalse);
    });

    test('is true once an option is chosen', () {
      final q = buildQuestion()..selectedOptionKey = 'C';
      expect(q.isAnswered, isTrue);
    });

    test('is true for a numerical response', () {
      final q = buildQuestion()..numericalAnswer = '42';
      expect(q.isAnswered, isTrue);
    });
  });

  group('QuestionItem time sync', () {
    // The autosave endpoint ADDS the seconds it receives, so only the
    // un-synced delta may ever be sent.
    test('reports all elapsed time before the first sync', () {
      final q = buildQuestion()..timeSpentSeconds = 30;
      expect(q.pendingTimeSeconds, 30);
    });

    test('reports nothing pending straight after a commit', () {
      final q = buildQuestion()..timeSpentSeconds = 30;
      q.commitPendingTime();
      expect(q.pendingTimeSeconds, 0);
    });

    test('reports only the delta accrued since the last commit', () {
      final q = buildQuestion()..timeSpentSeconds = 30;
      q.commitPendingTime();
      q.timeSpentSeconds += 12;
      expect(q.pendingTimeSeconds, 12);
    });

    test('never reports a negative delta', () {
      final q = buildQuestion()..timeSpentSeconds = 30;
      q.commitPendingTime();
      q.timeSpentSeconds = 5;
      expect(q.pendingTimeSeconds, 0);
    });
  });
}
