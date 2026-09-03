import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:flutter/material.dart';

class AppConstants {
  /// Host used for on-device debug builds. Override at build time:
  ///   flutter run --dart-define=API_HOST=192.168.1.50:8000
  static const String _defaultDevHost = '10.0.2.2:8000';
  static const String hostLanIp =
      String.fromEnvironment('API_HOST', defaultValue: _defaultDevHost);

  /// Base URL for the API.
  ///
  /// Release builds require `--dart-define=API_BASE_URL=https://...`; there is
  /// deliberately no plaintext-HTTP fallback baked into a shipped binary.
  static String get apiBaseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;

    if (kReleaseMode) {
      throw StateError(
        'API_BASE_URL is not configured. Build with '
        '--dart-define=API_BASE_URL=https://your-server/EXAMVERSE/api',
      );
    }

    if (kIsWeb) return 'http://localhost/EXAMVERSE/api';
    if (Platform.isAndroid) return 'http://$hostLanIp/EXAMVERSE/api';
    return 'http://127.0.0.1/EXAMVERSE/api';
  }

  // ── EXAMVERSE Colour System — Light theme: white + dark yellow ──────────
  // Every pair below is checked against WCAG AA (4.5:1 for body text).
  // Names are kept from the previous dark theme so all 600+ call sites keep
  // working; only the values changed.

  static const Color primaryDark = Color(0xFFFFFFFF);      // page background
  static const Color scaffoldDark = Color(0xFFFCFAF4);     // app bars, chrome
  static const Color cardDark = Color(0xFFFCFAF4);         // card surface
  static const Color surfaceElevated = Color(0xFFF5F0E1);  // raised surface
  static const Color cardBorder = Color(0xFFE3DBC5);       // hairline border

  // Signature accent: dark yellow. 4.92:1 on white, and white text on it is
  // also 4.92:1, so it works both as ink and as a button fill.
  static const Color accentYellow = Color(0xFF8A6D00);
  static const Color accentYellowDeep = Color(0xFF6B5400);
  static const Color accentYellowSoft = Color(0xFFC9A227);

  // Legacy accent names now resolve to the yellow family or an accessible
  // status colour, so existing widgets stay readable on a light background.
  static const Color accentCyan = accentYellow;
  static const Color accentBlue = accentYellowDeep;
  static const Color accentPurple = Color(0xFF6D28D9);
  static const Color accentViolet = Color(0xFF6D28D9);
  static const Color accentIndigo = accentYellow;
  static const Color accentEmerald = Color(0xFF15803D);
  static const Color accentGreen = Color(0xFF15803D);
  static const Color accentAmber = Color(0xFFB45309);
  static const Color accentRose = Color(0xFFB91C1C);

  // Typography — dark ink on light ground.
  static const Color textPrimary = Color(0xFF1A1A1A);      // 17.4:1 on white
  static const Color textSecondary = Color(0xFF54524B);    //  7.8:1 on white
  static const Color textMuted = Color(0xFF726F65);        //  5.0:1 on white

  /// Ink to place on top of a filled accent surface.
  static const Color onAccent = Color(0xFFFFFFFF);

  // Curated Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [accentYellow, accentYellowDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient aiGradient = LinearGradient(
    colors: [accentPurple, accentYellowDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient readinessGradient = LinearGradient(
    colors: [accentYellow, accentYellowSoft],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [Color(0xFF15803D), Color(0xFF22A354)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [accentYellowDeep, accentYellow],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFFFCFAF4), Color(0xFFF5F0E1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Spacing System (4, 8, 12, 16, 20, 24, 32, 40)
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;

  // Border Radius System (12–20px)
  static const double radiusSmall = 10.0;
  static const double radiusMedium = 14.0;
  static const double radiusCard = 18.0;
  static const double radiusHero = 24.0;

  // Reusable Soft Box Shadows
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 14,
      offset: const Offset(0, 3),
    ),
  ];

  static List<BoxShadow> glowShadow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.22),
      blurRadius: 18,
      spreadRadius: 1,
      offset: const Offset(0, 4),
    ),
  ];
}
