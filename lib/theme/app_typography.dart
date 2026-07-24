import 'package:flutter/material.dart';

import 'package:cedsif_overtime_mobile/theme/app_colors.dart';

abstract final class AppTypography {
  static const String uiFontFamily = 'Poppins';
  static const String bodyFontFamily = 'IBM Plex Sans';
  static const String numericFontFamily = 'IBM Plex Mono';

  static const TextStyle screenTitleLarge = TextStyle(
    color: AppColors.textStrong,
    fontFamily: uiFontFamily,
    fontSize: 26,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
  static const TextStyle screenTitle = TextStyle(
    color: AppColors.textStrong,
    fontFamily: uiFontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );
  static const TextStyle sectionTitle = TextStyle(
    color: AppColors.textPrimary,
    fontFamily: uiFontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
  static const TextStyle body = TextStyle(
    color: AppColors.textSecondary,
    fontFamily: bodyFontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );
  static const TextStyle bodyStrong = TextStyle(
    color: AppColors.textPrimary,
    fontFamily: bodyFontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  static const TextStyle label = TextStyle(
    color: AppColors.textPrimary,
    fontFamily: uiFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.25,
  );
  static const TextStyle labelStrong = TextStyle(
    color: AppColors.textPrimary,
    fontFamily: uiFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );
  static const TextStyle input = TextStyle(
    color: AppColors.textPrimary,
    fontFamily: uiFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.25,
  );
  static const TextStyle button = TextStyle(
    color: AppColors.onPrimary,
    fontFamily: uiFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
  static const TextStyle small = TextStyle(
    color: AppColors.textMuted,
    fontFamily: uiFontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );
  static const TextStyle timerLarge = TextStyle(
    color: AppColors.textStrong,
    fontFamily: numericFontFamily,
    fontSize: 52,
    fontWeight: FontWeight.w600,
    height: 1,
  );
  static const TextStyle numericTotal = TextStyle(
    color: AppColors.textStrong,
    fontFamily: numericFontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.1,
  );
  static const TextStyle historyTime = TextStyle(
    color: AppColors.textMuted,
    fontFamily: numericFontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
}
