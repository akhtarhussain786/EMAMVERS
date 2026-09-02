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

  // EXAMVERSE Color System — Premium Dark Futuristic Theme
  static const Color primaryDark = Color(0xFF080D18);      // Deepest background #080D18
  static const Color scaffoldDark = Color(0xFF101827);     // Secondary surface #101827
  static const Color cardDark = Color(0xFF151F32);         // Card background #151F32
  static const Color surfaceElevated = Color(0xFF1A263B);   // Elevated surface #1A263B
  static const Color cardBorder = Color(0x2694A3B8);       // Subtle border rgba(148,163,184,0.15)

  // Signature Accents
  static const Color accentCyan = Color(0xFF38BDF8);       // Primary Cyan #38BDF8
  static const Color accentBlue = Color(0xFF0284C7);       // Secondary Blue #0284C7
  static const Color accentPurple = Color(0xFF8B5CF6);     // Purple Accent #8B5CF6
  static const Color accentViolet = Color(0xFF6366F1);     // Royal Indigo / Violet
  static const Color accentIndigo = Color(0xFF6366F1);     // Alias for violet
  static const Color accentEmerald = Color(0xFF22C55E);    // Success #22C55E
  static const Color accentGreen = Color(0xFF22C55E);      // Alias for emerald
  static const Color accentAmber = Color(0xFFF59E0B);      // Warning #F59E0B
  static const Color accentRose = Color(0xFFEF4444);       // Danger #EF4444

  // Typography Hierarchy Text Colors
  static const Color textPrimary = Color(0xFFF8FAFC);     // Primary Text #F8FAFC
  static const Color textSecondary = Color(0xFF94A3B8);   // Secondary Text #94A3B8
  static const Color textMuted = Color(0xFF64748B);       // Captions & inactive #64748B

  // Curated Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [accentCyan, accentBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient aiGradient = LinearGradient(
    colors: [accentPurple, accentBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient readinessGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF0284C7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [Color(0xFF16A34A), accentEmerald],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFD97706), accentAmber],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF151F32), Color(0xFF101827)],
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
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> glowShadow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.35),
      blurRadius: 20,
      spreadRadius: 1,
      offset: const Offset(0, 4),
    ),
  ];
}
