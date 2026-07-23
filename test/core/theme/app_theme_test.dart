import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cedsif_overtime_mobile/core/theme/app_theme.dart';
import 'package:cedsif_overtime_mobile/theme/app_colors.dart';

void main() {
  test('exposes reachable default light and dark themes', () {
    expect(AppTheme.light.brightness, Brightness.light);
    expect(AppTheme.dark.brightness, Brightness.dark);
    expect(AppTheme.light.useMaterial3, isTrue);
    expect(AppTheme.dark.useMaterial3, isTrue);
  });

  test('maps the Portal do FAE tokens into the light Material theme', () {
    expect(AppTheme.light.colorScheme.primary, AppColors.primary);
    expect(AppTheme.light.colorScheme.secondary, AppColors.secondary);
    expect(AppTheme.light.colorScheme.error, AppColors.danger);
    expect(AppTheme.light.scaffoldBackgroundColor, AppColors.background);
    expect(
      AppTheme.light.textTheme.bodyMedium?.fontSize,
      greaterThanOrEqualTo(13),
    );
    expect(AppTheme.light.materialTapTargetSize, MaterialTapTargetSize.padded);
    expect(
      AppTheme.light.filledButtonTheme.style?.minimumSize?.resolve({})?.height,
      56,
    );
    expect(AppTheme.light.inputDecorationTheme.filled, isTrue);
    expect(AppTheme.light.inputDecorationTheme.fillColor, AppColors.canvas);
  });
}
