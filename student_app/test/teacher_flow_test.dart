import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_app/views/teacher/teacher_dashboard_view.dart';

void main() {
  group('StatusChip', () {
    Future<void> pump(WidgetTester t, String status) async {
      await t.pumpWidget(MaterialApp(home: Scaffold(body: StatusChip(status: status))));
    }

    testWidgets('an approved submission reads as Approved', (t) async {
      await pump(t, 'published');
      expect(find.text('Approved'), findsOneWidget);
    });

    testWidgets('a rejected submission tells the teacher to act', (t) async {
      await pump(t, 'rejected');
      expect(find.text('Needs changes'), findsOneWidget);
    });

    testWidgets('a pending submission reads as In review', (t) async {
      await pump(t, 'review');
      expect(find.text('In review'), findsOneWidget);
    });

    testWidgets('an unknown status degrades to Draft rather than blank', (t) async {
      await pump(t, '');
      expect(find.text('Draft'), findsOneWidget);
    });
  });
}
