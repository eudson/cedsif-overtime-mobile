import 'package:flutter/material.dart';

abstract final class AppColors {
  static const int primaryArgb = 0xFF147A52;
  static const int secondaryArgb = 0xFF1F9D63;

  static const Color primary = Color(primaryArgb);
  static const Color secondary = Color(secondaryArgb);
  static const Color success = Color(0xFF2E9E5B);
  static const Color successBackground = Color(0xFFDFF0E7);
  static const Color successSoft = Color(0xFFCDE3D6);
  static const Color successDark = Color(0xFF0F6A46);
  static const Color warning = Color(0xFFC77700);
  static const Color warningBackground = Color(0xFFFDEFC4);
  static const Color danger = Color(0xFFC0392B);
  static const Color dangerBackground = Color(0xFFFBEDEB);
  static const Color background = Color(0xFFF4F6FA);
  static const Color surface = Color(0xFFEEF1F5);
  static const Color surfaceAlternative = Color(0xFFEDF0F4);
  static const Color border = Color(0xFFDDE3EC);
  static const Color textPrimary = Color(0xFF1E2531);
  static const Color textStrong = Color(0xFF0B1220);
  static const Color textSecondary = Color(0xFF6E7681);
  static const Color textMuted = Color(0xFF8A94A2);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color canvas = Color(0xFFFFFFFF);
  static const Color disabled = Color(0xFFAAB6C8);
  static const Color offline = Color(0xFF667085);
  static const Color offlineBackground = Color(0xFFF0F2F6);
  static const Color transparent = Color(0x00000000);

  // Compatibility aliases used by the bootstrapped application.
  static const Color error = danger;
}
