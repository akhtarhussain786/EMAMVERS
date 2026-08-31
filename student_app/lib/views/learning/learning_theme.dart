import 'package:flutter/material.dart';

class LearningTheme {
  // Brand Colors
  static const Color primaryPurple = Color(0xFF5E42E5);
  static const Color primaryPurpleLight = Color(0xFF8E7CFF);
  static const Color primaryPurpleDark = Color(0xFF4832B6);
  static const Color softPurpleBg = Color(0xFFF3F0FF);
  static const Color scaffoldLightBg = Color(0xFFF8FAFC);
  static const Color surfaceWhite = Colors.white;

  // Text Colors
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMedium = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);

  // Status & Badges
  static const Color successGreen = Color(0xFF22C55E);
  static const Color successGreenBg = Color(0xFFDCFCE7);
  static const Color warningOrange = Color(0xFFF97316);
  static const Color warningOrangeBg = Color(0xFFFFEDD5);
  static const Color infoBlue = Color(0xFF3B82F6);
  static const Color infoBlueBg = Color(0xFFDBEAFE);
  static const Color starYellow = Color(0xFFF59E0B);

  // Card Borders & Shadows
  static Color borderLight = const Color(0xFFE2E8F0);
  
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.05),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> purpleButtonShadow = [
    BoxShadow(
      color: primaryPurple.withValues(alpha: 0.35),
      blurRadius: 14,
      offset: const Offset(0, 6),
    ),
  ];

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryPurple, primaryPurpleLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroCardGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
