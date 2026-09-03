import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:student_app/core/api_service.dart';
import 'package:student_app/main.dart';
import 'package:student_app/views/practice/build_practice_view.dart';
import 'package:student_app/views/teacher/teacher_dashboard_view.dart';
import 'package:student_app/views/teacher/submit_question_view.dart';

/// Drives the real UI against the live local API.
///
/// Run with:
///   flutter test integration_test/app_ui_test.dart -d chrome \
///     --dart-define=API_BASE_URL=http://127.0.0.1:8911/EXAMVERSE/api
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ApiService.clearSession();
  });

  /// Pumps until [finder] appears or the budget runs out. Network-backed
  /// screens settle at unpredictable times, so a fixed pumpAndSettle is flaky.
  Future<bool> waitFor(WidgetTester tester, Finder finder,
      {Duration timeout = const Duration(seconds: 20)}) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 300));
      if (finder.evaluate().isNotEmpty) return true;
    }
    return false;
  }

  /// Scrolls [target] into view inside the nearest scrollable, then taps it.
  /// Lazily-built list children do not exist in the tree until scrolled to.
  Future<void> scrollAndTap(WidgetTester tester, Finder target,
      {Finder? scrollable, double delta = 250}) async {
    final view = scrollable ?? find.byType(Scrollable).first;
    for (var i = 0; i < 12 && target.evaluate().isEmpty; i++) {
      await tester.drag(view, Offset(0, -delta));
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(target, findsWidgets, reason: 'target should be reachable by scrolling');
    await tester.ensureVisible(target.first);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(target.first);
    await tester.pump();
  }

  Future<void> login(WidgetTester tester, String identity, String password) async {
    await tester.pumpWidget(const ExamVerseApp(initiallyAuthenticated: false));
    expect(await waitFor(tester, find.byType(TextField)), isTrue,
        reason: 'login form should render');

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), identity);
    await tester.pump();
    await tester.enterText(fields.at(1), password);
    await tester.pump();

    await tester.tap(find.text('Log In to ExamVerse'));
    await tester.pump();
  }

  group('STUDENT', () {
    testWidgets('logs in and lands on the home dashboard', (tester) async {
      await login(tester, 'student1@examverse.com', 'NewStudentPass9');
      expect(await waitFor(tester, find.text('Practice')), isTrue,
          reason: 'home quick actions should render after login');
    });

    testWidgets('Practice button opens the mock builder', (tester) async {
      await login(tester, 'student1@examverse.com', 'NewStudentPass9');
      expect(await waitFor(tester, find.text('Practice')), isTrue);

      await scrollAndTap(tester, find.text('Practice'));

      expect(await waitFor(tester, find.byType(BuildPracticeView)), isTrue,
          reason: 'Practice must open the builder, not the AI coach');
      expect(await waitFor(tester, find.text('Build Your Test')), isTrue);
    });

    testWidgets('builder: selecting a subject and starting produces a test', (tester) async {
      await login(tester, 'student1@examverse.com', 'NewStudentPass9');
      expect(await waitFor(tester, find.text('Practice')), isTrue);
      await scrollAndTap(tester, find.text('Practice'));
      expect(await waitFor(tester, find.byKey(const Key('practice_form'))), isTrue);

      // Start is guarded by validation until a subject is chosen.
      await scrollAndTap(tester, find.byKey(const Key('start_practice')));
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.textContaining('Choose at least one subject'), findsOneWidget,
          reason: 'starting with no subject must be rejected in the UI');

      // Pick the first available subject.
      final subject = find.byWidgetPredicate(
          (w) => w is GestureDetector && w.key.toString().contains('subject_'));
      expect(subject, findsWidgets, reason: 'at least one subject should be offered');
      await tester.tap(subject.first);
      await tester.pump();

      // Use a preset so the counts are sane for a small local bank.
      final preset = find.byKey(const Key('preset_10'));
      if (preset.evaluate().isNotEmpty) {
        await tester.tap(preset);
        await tester.pump();
      }

      await scrollAndTap(tester, find.byKey(const Key('start_practice')));

      // The player replaces the builder once the paper is assembled.
      final started = await waitFor(
          tester, find.textContaining('Question 1'), timeout: const Duration(seconds: 25));
      expect(started || find.textContaining('available').evaluate().isNotEmpty, isTrue,
          reason: 'either the test starts, or the UI explains the bank is short');
    });

    testWidgets('difficulty chips are all selectable', (tester) async {
      await login(tester, 'student1@examverse.com', 'NewStudentPass9');
      expect(await waitFor(tester, find.text('Practice')), isTrue);
      await scrollAndTap(tester, find.text('Practice'));
      expect(await waitFor(tester, find.byKey(const Key('practice_form'))), isTrue);

      for (final d in ['mixed', 'easy', 'medium', 'hard']) {
        await scrollAndTap(tester, find.byKey(Key('difficulty_$d')));
      }
    });
  });

  group('TEACHER', () {
    testWidgets('logs in and sees the teacher panel, not the student shell', (tester) async {
      await login(tester, 'ramesh.teacher@examverse.com', 'TeacherPass#1');
      expect(await waitFor(tester, find.byType(TeacherDashboardView)), isTrue,
          reason: 'a teacher must land on the teacher panel');
      expect(await waitFor(tester, find.text('Teacher Panel')), isTrue);
    });

    testWidgets('New Question opens the authoring form with a department picker', (tester) async {
      await login(tester, 'ramesh.teacher@examverse.com', 'TeacherPass#1');
      expect(await waitFor(tester, find.text('New Question')), isTrue);

      await tester.tap(find.text('New Question'));
      await tester.pump();

      expect(await waitFor(tester, find.byType(SubmitQuestionView)), isTrue);
      expect(await waitFor(tester, find.text('Exam / Department')), isTrue,
          reason: 'the form must ask which department the question is for');
      expect(find.text('Subject'), findsOneWidget);
    });

    testWidgets('submitting an empty form surfaces validation, not a crash', (tester) async {
      await login(tester, 'ramesh.teacher@examverse.com', 'TeacherPass#1');
      expect(await waitFor(tester, find.text('New Question')), isTrue);
      await tester.tap(find.text('New Question'));
      await tester.pump();
      expect(await waitFor(tester, find.byType(SubmitQuestionView)), isTrue);

      await scrollAndTap(tester, find.text('Submit for Review'));
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.textContaining('required'), findsWidgets,
          reason: 'empty submission should show field errors');
    });

    testWidgets('My Submissions opens and filters', (tester) async {
      await login(tester, 'ramesh.teacher@examverse.com', 'TeacherPass#1');
      expect(await waitFor(tester, find.text('My Submissions')), isTrue);

      await scrollAndTap(tester, find.text('My Submissions'));
      expect(await waitFor(tester, find.text('In review')), isTrue,
          reason: 'the status filter row should render');

      // 'Approved' appears as both a filter chip and a status badge, so target
      // the chip specifically.
      final approvedChip = find.descendant(
        of: find.byType(ChoiceChip),
        matching: find.text('Approved'),
      );
      expect(approvedChip, findsOneWidget);
      await tester.tap(approvedChip);
      await tester.pump(const Duration(seconds: 3));
    });
  });

  group('SESSION', () {
    testWidgets('a wrong password is reported and does not sign the user in', (tester) async {
      await login(tester, 'student1@examverse.com', 'definitely-wrong');
      await tester.pump(const Duration(seconds: 3));
      expect(find.byType(TextField), findsWidgets,
          reason: 'a failed login must stay on the login screen');
    });
  });
}
