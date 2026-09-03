import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:student_app/core/constants.dart';
import 'package:student_app/widgets/design_system_widgets.dart';
import 'package:student_app/widgets/premium_cards.dart';

/// Walks the *rendered* widget tree and checks every Text against the actual
/// background painted behind it. Unlike a source-level scan this respects real
/// nesting, so it catches white-on-white and dark-on-dark for certain.

import 'contrast_util.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppConstants.primaryDark,
        colorScheme: const ColorScheme.light(
          primary: AppConstants.accentYellow,
          onPrimary: AppConstants.onAccent,
          surface: AppConstants.cardDark,
          onSurface: AppConstants.textPrimary,
        ),
      ),
      home: Scaffold(
        backgroundColor: AppConstants.primaryDark,
        body: SingleChildScrollView(child: child),
      ),
    ));
    await tester.pump();
  }

  testWidgets('design-system widgets are readable on the light theme', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 2600));
    await pump(tester, Column(children: [
      const SectionHeader(title: 'Section Header'),
      PrimaryButton(label: 'Primary Button', onPressed: () {}),
      SecondaryButton(label: 'Secondary Button', onPressed: () {}),
      const ExamVerseCard(child: Text('Body text inside a card',
          style: TextStyle(color: AppConstants.textPrimary))),
      const StatCard(label: 'Accuracy', value: '82%', icon: Icons.check, color: AppConstants.accentEmerald),
      const EmptyStateWidget(icon: Icons.inbox, title: 'Nothing here', description: 'An empty state'),
    ]));

    final failures = await auditContrast(tester, 'design-system');
    expect(failures, isEmpty, reason: 'unreadable text:\n${failures.join('\n')}');
  });

  testWidgets('premium cards are readable on the light theme', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 3000));
    await pump(tester, Column(children: [
      const RankCard(rank: 12, percentile: 94.2, rankImprovementText: 'up 4 places', bestRank: 8),
      LostMarksCard(totalLost: 18, onTapCreatePlan: () {}),
    ]));

    final failures = await auditContrast(tester, 'premium-cards');
    expect(failures, isEmpty, reason: 'unreadable text:\n${failures.join('\n')}');
  });

  test('palette tokens meet WCAG AA against their surfaces', () {
    final checks = <String, List<Color>>{
      'textPrimary on page':      [AppConstants.textPrimary, AppConstants.primaryDark],
      'textSecondary on page':    [AppConstants.textSecondary, AppConstants.primaryDark],
      'textMuted on page':        [AppConstants.textMuted, AppConstants.primaryDark],
      'textPrimary on card':      [AppConstants.textPrimary, AppConstants.cardDark],
      'textSecondary on card':    [AppConstants.textSecondary, AppConstants.cardDark],
      'textMuted on card':        [AppConstants.textMuted, AppConstants.cardDark],
      'accentYellow on page':     [AppConstants.accentYellow, AppConstants.primaryDark],
      'onAccent on accentYellow': [AppConstants.onAccent, AppConstants.accentYellow],
      'success on card':          [AppConstants.accentEmerald, AppConstants.cardDark],
      'danger on card':           [AppConstants.accentRose, AppConstants.cardDark],
      'warning on card':          [AppConstants.accentAmber, AppConstants.cardDark],
    };
    final bad = <String>[];
    checks.forEach((label, pair) {
      final r = contrastRatio(pair[0], pair[1]);
      if (r < 4.5) bad.add('$label = ${r.toStringAsFixed(2)}:1');
    });
    expect(bad, isEmpty, reason: 'below WCAG AA:\n${bad.join('\n')}');
  });
}
