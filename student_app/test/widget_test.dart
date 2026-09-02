import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_app/main.dart';

void main() {
  testWidgets('unauthenticated launch shows the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ExamVerseApp(initiallyAuthenticated: false));
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    // The password field is the reliable marker for the auth screen.
    expect(find.byType(TextField), findsWidgets);
  });
}
