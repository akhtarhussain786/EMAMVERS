import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:student_app/core/constants.dart';

/// Contrast auditing shared by the widget test and the integration test.
///
/// Walks the rendered tree and compares each Text against the background
/// actually painted behind it, so it catches white-on-white and dark-on-dark
/// with real layout rather than a source-level guess.

double _lin(double c) => c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
double luminance(Color c) =>
    0.2126 * _lin(c.r) + 0.7152 * _lin(c.g) + 0.0722 * _lin(c.b);
double contrastRatio(Color a, Color b) {
  final la = luminance(a), lb = luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// Flattens a possibly-translucent colour over its backdrop.
Color flattenOver(Color fg, Color bg) {
  final a = fg.a;
  return Color.from(
    alpha: 1.0,
    red: fg.r * a + bg.r * (1 - a),
    green: fg.g * a + bg.g * (1 - a),
    blue: fg.b * a + bg.b * (1 - a),
  );
}

/// Nearest painted background behind [element], walking towards the root.
Color backgroundBehind(Element element, Color fallback) {
  Color? found;
  element.visitAncestorElements((a) {
    final w = a.widget;
    if (w is Container && w.decoration is BoxDecoration) {
      final d = w.decoration as BoxDecoration;
      if (d.gradient is LinearGradient) {
        final stops = (d.gradient as LinearGradient).colors;
        found = stops.first; return false;
      }
      if (d.color != null && d.color!.a > 0.55) { found = d.color; return false; }
    }
    if (w is Container && w.color != null && w.color!.a > 0.55) { found = w.color; return false; }
    if (w is DecoratedBox && w.decoration is BoxDecoration) {
      final d = w.decoration as BoxDecoration;
      if (d.gradient is LinearGradient) { found = (d.gradient as LinearGradient).colors.first; return false; }
      if (d.color != null && d.color!.a > 0.55) { found = d.color; return false; }
    }
    if (w is Card && w.color != null) { found = w.color; return false; }
    if (w is Material && w.color != null && w.color!.a > 0.55) { found = w.color; return false; }
    if (w is Scaffold) { found = w.backgroundColor ?? fallback; return false; }
    return true;
  });
  return found ?? fallback;
}

Future<List<String>> auditContrast(WidgetTester tester, String screen) async {
  final failures = <String>[];
  for (final element in find.byType(Text).evaluate()) {
    final text = element.widget as Text;
    final label = text.data ?? '';
    if (label.trim().isEmpty) continue;

    final style = text.style;
    final fg = style?.color;
    if (fg == null) continue; // inherits from theme; covered by the theme test

    final bg = backgroundBehind(element, AppConstants.primaryDark);
    final ratio = contrastRatio(flattenOver(fg, bg), bg);
    if (ratio < 3.0) {
      failures.add('$screen: "${label.length > 34 ? '${label.substring(0, 34)}…' : label}" '
          '${ratio.toStringAsFixed(2)}:1');
    }
  }
  return failures;
}

