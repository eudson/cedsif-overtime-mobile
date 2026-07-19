import 'package:flutter_test/flutter_test.dart';

import 'package:cedsif_overtime_mobile/core/branding/branding_config.dart';
import 'package:cedsif_overtime_mobile/core/branding/branding_defaults.dart';
import 'package:cedsif_overtime_mobile/core/constants/app_colors.dart';

void main() {
  test('uses the resolved application branding defaults', () {
    const config = BrandingConfig();

    expect(config.appNameKey, BrandingDefaults.appNameKey);
    expect(config.appNameKey, 'app.title');
    expect(config.primaryColorArgb, BrandingDefaults.primaryColorArgb);
    expect(config.secondaryColorArgb, BrandingDefaults.secondaryColorArgb);
    expect(config.primaryColorArgb, AppColors.primary.toARGB32());
    expect(config.secondaryColorArgb, AppColors.secondary.toARGB32());
  });

  test('supports tenant-specific immutable overrides', () {
    const config = BrandingConfig();

    final updated = config.copyWith(
      primaryColorArgb: AppColors.error.toARGB32(),
    );

    expect(updated.primaryColorArgb, AppColors.error.toARGB32());
    expect(config.primaryColorArgb, AppColors.primary.toARGB32());
  });
}
