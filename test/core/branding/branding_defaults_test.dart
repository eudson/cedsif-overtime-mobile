import 'package:flutter_test/flutter_test.dart';

import 'package:cedsif_overtime_mobile/core/branding/branding_defaults.dart';
import 'package:cedsif_overtime_mobile/core/constants/app_colors.dart';

void main() {
  test('uses the canonical application ARGB values', () {
    expect(BrandingDefaults.primaryColorArgb, AppColors.primaryArgb);
    expect(BrandingDefaults.secondaryColorArgb, AppColors.secondaryArgb);
  });
}
