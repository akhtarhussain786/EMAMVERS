import 'package:flutter/material.dart';

class AppConstants {
  /// Host used for on-device debug builds. Override at build time:
  ///   flutter run --dart-define=API_HOST=192.168.31.120
  static const String _defaultDevHost = '192.168.31.120';
  static const String hostLanIp =
      String.fromEnvironment('API_HOST', defaultValue: _defaultDevHost);

  /// Staging server API base URL
  static const String stagingBaseUrl = 'https://staging.yatharthinstitution.in/api';

  /// Base URL for the API.
  static String get apiBaseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;

    return stagingBaseUrl;
  }



  // ── EXAMVERSE Modern UI Colour System — Royal Blue & Clean Surfaces ─────
  static const Color primaryDark = Color(0xFFFFFFFF);      // page background
  static const Color scaffoldDark = Color(0xFFF8FAFC);     // app bars, chrome
  static const Color cardDark = Color(0xFFFFFFFF);         // card surface
  static const Color surfaceElevated = Color(0xFFF1F5F9);  // raised surface
  static const Color cardBorder = Color(0xFFE2E8F0);       // hairline border

  // Signature brand accents (Royal Blue & Electric Blue from Design Mockup)
  static const Color accentBlue = Color(0xFF1D4ED8);
  static const Color accentCyan = Color(0xFF2563EB);
  static const Color accentIndigo = Color(0xFF1E40AF);
  static const Color accentYellow = Color(0xFFD97706);
  static const Color accentYellowDeep = Color(0xFFB45309);
  static const Color accentYellowSoft = Color(0xFFF59E0B);
  static const Color accentPurple = Color(0xFF7C3AED);
  static const Color accentViolet = Color(0xFF7C3AED);
  static const Color accentEmerald = Color(0xFF10B981);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color accentRose = Color(0xFFEF4444);

  // Typography — high-contrast modern dark ink
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF64748B);

  /// Ink to place on top of a filled accent surface.
  static const Color onAccent = Color(0xFFFFFFFF);

  // Curated Gradients from Image 2
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF003884), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF00152E), Color(0xFF003884), Color(0xFF1D4ED8)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient aiGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient readinessGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF38BDF8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
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
