import 'package:flutter_test/flutter_test.dart';

import 'package:cedsif_overtime_mobile/core/branding/branding_config.dart';
import 'package:cedsif_overtime_mobile/core/branding/branding_defaults.dart';
import 'package:cedsif_overtime_mobile/core/constants/app_colors.dart';

void main() {
  test('uses the resolved application branding defaults', () {
    const config = BrandingConfig();

    expect(config.appName, BrandingDefaults.appName);
    expect(config.primaryColor, AppColors.primary);
    expect(config.secondaryColor, AppColors.secondary);
  });

  test('supports tenant-specific immutable overrides', () {
    const config = BrandingConfig();

    final updated = config.copyWith(primaryColor: AppColors.error);

    expect(updated.primaryColor, AppColors.error);
    expect(config.primaryColor, AppColors.primary);
  });
}
