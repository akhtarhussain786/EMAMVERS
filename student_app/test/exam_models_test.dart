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

  optionOrderingTests();

  paperSizeTests();
}

// ---------------------------------------------------------------------------
// Option ordering and question type.
//
// The server shuffles option order per attempt and returns the options in that
// order, but the player used to render a hardcoded ['A','B','C','D'] and look
// each option up by key, so the shuffle never reached the candidate and a paper
// with five options silently lost one. These cover the ordering contract.
// ---------------------------------------------------------------------------

QuestionOption opt(String key, String text, {String language = 'en'}) =>
    QuestionOption(id: 0, optionKey: key, language: language, optionText: text);

QuestionItem questionWith({
  required List<QuestionOption> options,
  String questionType = 'MCQ',
}) =>
    QuestionItem(
      questionId: 42,
      questionOrder: 1,
      positiveMarks: 2,
      negativeMarks: 0.5,
      questionType: questionType,
      translations: const [],
      options: options,
    );

void optionOrderingTests() {
  group('QuestionItem.orderedOptionKeys', () {
    test('preserves the shuffled order the server sent', () {
      final q = questionWith(options: [
        opt('C', 'third'),
        opt('A', 'first'),
        opt('D', 'fourth'),
        opt('B', 'second'),
      ]);
      expect(q.orderedOptionKeys, ['C', 'A', 'D', 'B']);
    });

    test('collapses the bilingual rows to one entry per key, keeping order', () {
      // The paper ships 4 English + 4 Hindi rows for a 4-option question.
      final q = questionWith(options: [
        opt('C', 'third'), opt('C', 'तीसरा', language: 'hi'),
        opt('B', 'second'), opt('B', 'दूसरा', language: 'hi'),
        opt('A', 'first'), opt('A', 'पहला', language: 'hi'),
        opt('D', 'fourth'), opt('D', 'चौथा', language: 'hi'),
      ]);
      expect(q.orderedOptionKeys, ['C', 'B', 'A', 'D']);
    });

    test('keeps a fifth option instead of dropping it', () {
      final q = questionWith(options: [
        opt('A', 'a'), opt('B', 'b'), opt('C', 'c'), opt('D', 'd'), opt('E', 'e'),
      ]);
      expect(q.orderedOptionKeys, ['A', 'B', 'C', 'D', 'E']);
      expect(q.orderedOptionKeys.length, 5);
    });

    test('falls back to A-D for a choice question with no options', () {
      expect(questionWith(options: const []).orderedOptionKeys,
          ['A', 'B', 'C', 'D']);
    });

    test('offers no option keys for a typed-answer question', () {
      final q = questionWith(options: const [], questionType: 'NUMERICAL');
      expect(q.isNumericalEntry, isTrue);
      expect(q.orderedOptionKeys, isEmpty);
    });

    test('treats TITA and NAT as typed-answer types', () {
      for (final t in ['TITA', 'NAT', 'numerical', 'Fill_In_The_Blank']) {
        expect(questionWith(options: const [], questionType: t).isNumericalEntry,
            isTrue,
            reason: '$t should be a typed-answer question');
      }
      expect(questionWith(options: const []).isNumericalEntry, isFalse);
    });
  });
}

// ---------------------------------------------------------------------------
// Paper size.
//
// The exam detail list showed ep.total_questions — the pattern's design — so a
// mock advertised 100 questions over a bank holding 17 and the candidate sat
// 17. It also derived marks as questions x 2 instead of reading the real
// total. These cover the figures the card is given.
// ---------------------------------------------------------------------------
void paperSizeTests() {
  group('TestItem paper size', () {
    Map<String, dynamic> row({
      int total = 17,
      dynamic marks = '34.00',
      int pattern = 100,
      dynamic playable = true,
      dynamic short = true,
    }) =>
        {
          'id': 5,
          'title': 'SSC CGL Mock',
          'test_type': 'full_mock',
          'is_paid': 0,
          'price': '0.00',
          'total_questions': total,
          'total_marks': marks,
          'pattern_total_questions': pattern,
          'is_playable': playable,
          'is_short_of_pattern': short,
          'total_attempts': 4,
        };

    test('reports the paper it will sit, not the pattern target', () {
      final t = TestItem.fromJson(row());
      expect(t.totalQuestions, 17);
      expect(t.patternTotalQuestions, 100);
      expect(t.isShortOfPattern, isTrue);
    });

    test('takes marks from the payload rather than assuming two per question',
        () {
      // A 17-question paper at 2 marks each is 34; questions x 2 agrees here,
      // so use a scheme where it does not to catch the assumption.
      final t = TestItem.fromJson(row(total: 10, marks: '40.00'));
      expect(t.totalMarks, 40.0,
          reason: 'questions x 2 would have produced 20');
    });

    test('a paper with nothing in it is not playable', () {
      final t = TestItem.fromJson(row(total: 0, marks: '0.00', playable: false));
      expect(t.isPlayable, isFalse);
      expect(t.totalQuestions, 0);
    });

    test('falls back to the question count when the flag is absent', () {
      final withQs = row()..remove('is_playable');
      expect(TestItem.fromJson(withQs).isPlayable, isTrue);
      final empty = row(total: 0)..remove('is_playable');
      expect(TestItem.fromJson(empty).isPlayable, isFalse);
    });

    test('a full paper is not flagged short', () {
      final t = TestItem.fromJson(row(total: 100, marks: '200.00', short: false));
      expect(t.isShortOfPattern, isFalse);
    });
  });
}
