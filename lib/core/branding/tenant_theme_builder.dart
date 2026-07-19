import 'package:flutter/material.dart';

import 'package:cedsif_overtime_mobile/core/branding/branding_config.dart';
import 'package:cedsif_overtime_mobile/core/constants/app_colors.dart';
import 'package:cedsif_overtime_mobile/core/constants/app_text_styles.dart';
import 'package:cedsif_overtime_mobile/core/constants/constants.dart';

abstract final class TenantThemeBuilder {
  static ThemeData light(BrandingConfig branding) =>
      _build(brightness: Brightness.light, branding: branding);

  static ThemeData dark(BrandingConfig branding) =>
      _build(brightness: Brightness.dark, branding: branding);

  static ThemeData _build({
    required Brightness brightness,
    required BrandingConfig branding,
  }) {
    final primaryColor = Color(branding.primaryColorArgb);
    final secondaryColor = Color(branding.secondaryColorArgb);
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: brightness,
        ).copyWith(
          primary: primaryColor,
          secondary: secondaryColor,
          error: AppColors.error,
        );
    final textTheme =
        const TextTheme(
          headlineSmall: AppTextStyles.headline,
          titleLarge: AppTextStyles.title,
          bodyLarge: AppTextStyles.body,
          bodyMedium: AppTextStyles.body,
          labelLarge: AppTextStyles.label,
        ).apply(
          bodyColor: brightness == Brightness.light
              ? AppColors.textPrimary
              : colorScheme.onSurface,
          displayColor: brightness == Brightness.light
              ? AppColors.textPrimary
              : colorScheme.onSurface,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: brightness == Brightness.light
          ? AppColors.background
          : colorScheme.surface,
      dividerColor: AppColors.border,
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppConstants.buttonHeight),
          textStyle: AppTextStyles.label,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
        ),
      ),
    );
  }
}
