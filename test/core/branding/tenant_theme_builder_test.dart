import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cedsif_overtime_mobile/core/branding/branding_config.dart';
import 'package:cedsif_overtime_mobile/core/branding/tenant_theme_builder.dart';
import 'package:cedsif_overtime_mobile/core/constants/app_colors.dart';

void main() {
  test('builds a Material 3 light theme from tenant branding', () {
    final branding = BrandingConfig(
      primaryColorArgb: AppColors.error.toARGB32(),
    );

    final theme = TenantThemeBuilder.light(branding);

    expect(theme.useMaterial3, isTrue);
    expect(theme.brightness, Brightness.light);
    expect(theme.colorScheme.primary, AppColors.error);
  });

  test('builds a Material 3 dark theme from tenant branding', () {
    final branding = BrandingConfig(
      secondaryColorArgb: AppColors.border.toARGB32(),
    );

    final theme = TenantThemeBuilder.dark(branding);

    expect(theme.useMaterial3, isTrue);
    expect(theme.brightness, Brightness.dark);
    expect(theme.colorScheme.secondary, AppColors.border);
  });
}
