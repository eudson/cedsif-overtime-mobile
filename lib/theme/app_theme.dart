import 'package:flutter/material.dart';

import 'package:cedsif_overtime_mobile/theme/app_colors.dart';
import 'package:cedsif_overtime_mobile/theme/app_spacing.dart';
import 'package:cedsif_overtime_mobile/theme/app_typography.dart';

abstract final class AppTheme {
  static final ThemeData light = lightFor();
  static final ThemeData dark = darkFor();

  static ThemeData lightFor({
    Color primary = AppColors.primary,
    Color secondary = AppColors.secondary,
  }) {
    final colorScheme = const ColorScheme.light().copyWith(
      primary: primary,
      onPrimary: AppColors.onPrimary,
      secondary: secondary,
      onSecondary: AppColors.onPrimary,
      error: AppColors.danger,
      onError: AppColors.onPrimary,
      surface: AppColors.canvas,
      onSurface: AppColors.textPrimary,
      outline: AppColors.border,
      surfaceContainerHighest: AppColors.surface,
    );

    return _baseTheme(colorScheme).copyWith(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
    );
  }

  static ThemeData darkFor({
    Color primary = AppColors.primary,
    Color secondary = AppColors.secondary,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      secondary: secondary,
      brightness: Brightness.dark,
    ).copyWith(primary: primary, secondary: secondary, error: AppColors.danger);
    return _baseTheme(colorScheme).copyWith(brightness: Brightness.dark);
  }

  static ThemeData _baseTheme(ColorScheme colorScheme) {
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
      borderSide: const BorderSide(
        color: AppColors.border,
        width: AppSpacing.borderWidth,
      ),
    );
    final textTheme = const TextTheme(
      headlineLarge: AppTypography.screenTitleLarge,
      headlineMedium: AppTypography.screenTitle,
      titleLarge: AppTypography.sectionTitle,
      bodyLarge: AppTypography.body,
      bodyMedium: AppTypography.body,
      labelLarge: AppTypography.labelStrong,
      labelMedium: AppTypography.label,
      labelSmall: AppTypography.small,
    );
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: AppTypography.uiFontFamily,
      textTheme: textTheme,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      dividerColor: AppColors.border,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.canvas,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space16,
          vertical: AppSpacing.space16,
        ),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: AppSpacing.borderWidthStrong,
          ),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(
            color: AppColors.danger,
            width: AppSpacing.borderWidth,
          ),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(
            color: AppColors.danger,
            width: AppSpacing.borderWidthStrong,
          ),
        ),
        hintStyle: AppTypography.body.copyWith(color: AppColors.textMuted),
        errorStyle: AppTypography.small.copyWith(color: AppColors.danger),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
          backgroundColor: colorScheme.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.disabled,
          disabledForegroundColor: AppColors.onPrimary,
          textStyle: AppTypography.labelStrong,
          shape: buttonShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
          foregroundColor: colorScheme.primary,
          side: BorderSide(
            color: colorScheme.primary,
            width: AppSpacing.borderWidthStrong,
          ),
          textStyle: AppTypography.labelStrong,
          shape: buttonShape,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: AppSpacing.bottomBarHeight,
        backgroundColor: AppColors.canvas,
        indicatorColor: AppColors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppTypography.label.copyWith(
            color: selected ? colorScheme.primary : AppColors.textMuted,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? colorScheme.primary : AppColors.textMuted,
            size: AppSpacing.iconMedium,
          );
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: AppSpacing.borderWidth,
        space: AppSpacing.borderWidth,
      ),
    );
  }
}
