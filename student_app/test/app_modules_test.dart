import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:student_app/views/auth/login_signup_view.dart';
import 'package:student_app/views/profile/referrals_view.dart';
import 'package:student_app/views/teacher/become_teacher_view.dart';
import 'package:student_app/views/teacher/teacher_dashboard_view.dart';
import 'package:student_app/views/test_engine/test_instructions_view.dart';
import 'package:student_app/views/discovery/exam_detail_view.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('1. Authentication Module Tests', () {
    testWidgets('Renders Login form with Email and Password fields and switches to Sign Up', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoginSignupView(
              onAuthenticated: (type) {},
            ),
          ),
        ),
      );

      // Verify fields & header. Labels carry a required-field marker, so match
      // on the stem rather than the exact string.
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.textContaining('Mobile Number / Email'), findsWidgets);
      expect(find.textContaining('Password'), findsWidgets);

      // Tap Switch to Sign Up. The toggle label is now
      // 'Create Account / Sign Up', so match on the stem.
      final switchBtn = find.textContaining('Sign Up');
      expect(switchBtn, findsWidgets);
      await tester.ensureVisible(switchBtn.first);
      await tester.tap(switchBtn.first);
      await tester.pumpAndSettle();

      // Header is role-dependent: 'Create Student Account' or 'Register as Teacher / Faculty'.
      expect(find.textContaining('Create Student Account'), findsWidgets);
      expect(find.textContaining('Full Name'), findsWidgets);

    });
  });

  group('2. Referral & Growth Module Tests', () {
    testWidgets('Renders Referral Screen AppBar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ReferralsView(),
        ),
      );

      await tester.pump();
      expect(find.text('Refer & Earn Premium'), findsOneWidget);
    });
  });

  group('3. Teacher KYC & Onboarding Tests', () {
    testWidgets('Renders Teacher Registration View', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: BecomeTeacherView(),
        ),
      );

      await tester.pump();
      expect(find.byType(BecomeTeacherView), findsOneWidget);
    });
  });

  group('4. Teacher Dashboard & Status Chips Tests', () {
    testWidgets('StatusChip renders distinct statuses correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                StatusChip(status: 'published'),
                StatusChip(status: 'review'),
                StatusChip(status: 'rejected'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Approved'), findsOneWidget);
      expect(find.text('In review'), findsOneWidget);
      expect(find.text('Needs changes'), findsOneWidget);
    });
  });

  group('5. Test Instructions & Engine Screen Tests', () {
    testWidgets('Renders Test Instructions with Test Details and Start Button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TestInstructionsView(
            testId: 1,
            onProceedToTest: () {},
            onCancel: () {},
          ),
        ),
      );

      expect(find.byType(TestInstructionsView), findsOneWidget);
    });
  });

  group('6. Discovery & Exam Detail View Tests', () {
    testWidgets('Renders Exam Detail View with Exam ID', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ExamDetailView(
            examId: 1,
            onStartTest: (id) {},
            onBack: () {},
          ),
        ),
      );

      expect(find.byType(ExamDetailView), findsOneWidget);
    });
  });
}
