import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_app/widgets/premium_cards.dart';

/// Both of these cards feed a value straight into a progress indicator, which
/// asserts on NaN or anything outside 0..1. AiMissionCard divided by
/// totalCount with no guard, so a mission with no items produced NaN, and
/// ReadinessCard passed score/100 unclamped.
Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  group('AiMissionCard progress', () {
    testWidgets('survives a mission with no items', (tester) async {
      await tester.pumpWidget(_wrap(AiMissionCard(
        completedCount: 0,
        totalCount: 0,
        onTapMission: () {},
      )));
      expect(tester.takeException(), isNull);
      final bar = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator));
      expect(bar.value, 0.0);
    });

    testWidgets('reports real progress when there are items', (tester) async {
      await tester.pumpWidget(_wrap(AiMissionCard(
        completedCount: 3,
        totalCount: 4,
        onTapMission: () {},
      )));
      expect(tester.takeException(), isNull);
      expect(
          tester
              .widget<LinearProgressIndicator>(
                  find.byType(LinearProgressIndicator))
              .value,
          0.75);
    });

    testWidgets('clamps a count that overshoots the total', (tester) async {
      await tester.pumpWidget(_wrap(AiMissionCard(
        completedCount: 9,
        totalCount: 4,
        onTapMission: () {},
      )));
      expect(tester.takeException(), isNull);
      expect(
          tester
              .widget<LinearProgressIndicator>(
                  find.byType(LinearProgressIndicator))
              .value,
          1.0);
    });
  });

  group('ReadinessCard gauge', () {
    testWidgets('clamps a score outside 0..100', (tester) async {
      for (final score in [-20, 0, 55, 140]) {
        await tester.pumpWidget(_wrap(ReadinessCard(
          score: score,
          statusText: 'Ready',
          monthlyChange: '+2',
          onTapAiTwin: () {},
        )));
        expect(tester.takeException(), isNull, reason: 'score $score');
        final gauge = tester.widget<CircularProgressIndicator>(
            find.byType(CircularProgressIndicator));
        expect(gauge.value, inInclusiveRange(0.0, 1.0),
            reason: 'score $score must not leave the 0..1 range');
      }
    });
  });
}
