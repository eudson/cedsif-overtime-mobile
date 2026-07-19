import 'package:flutter/material.dart';

import 'package:cedsif_overtime_mobile/core/constants/app_colors.dart';

abstract final class AppTextStyles {
  static const TextStyle headline = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 32,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle title = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle body = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
    height: 1.5,
  );
  static const TextStyle label = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
}
