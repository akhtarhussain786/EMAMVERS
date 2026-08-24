import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class AppConstants {
  // Physical Phone Wi-Fi IP & Open Port 8000 Server: 10.64.239.209:8000
  static const String hostLanIp = '10.64.239.209:8000';

  static String get apiBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/EXAMVERSE/api';
    } else if (Platform.isAndroid) {
      return 'http://$hostLanIp/EXAMVERSE/api';
    } else {
      return 'http://127.0.0.1:8000/EXAMVERSE/api';
    }
  }

  // App Theme Colors
  static const Color primaryDark = Color(0xFF0F172A);
  static const Color cardDark = Color(0xFF1E293B);
  static const Color cardBorder = Color(0xFF334155);
  static const Color accentBlue = Color(0xFF38BDF8);
  static const Color accentIndigo = Color(0xFF6366F1);
  static const Color accentEmerald = Color(0xFF10B981);
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [accentIndigo, accentBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [Color(0xFF059669), accentEmerald],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
