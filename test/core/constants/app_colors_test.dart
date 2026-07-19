import 'package:flutter_test/flutter_test.dart';

import 'package:cedsif_overtime_mobile/core/constants/app_colors.dart';

void main() {
  test('primary colors are projected from canonical ARGB integers', () {
    expect(AppColors.primary.toARGB32(), AppColors.primaryArgb);
    expect(AppColors.secondary.toARGB32(), AppColors.secondaryArgb);
    expect(AppColors.primaryArgb, 0xFF005EA8);
    expect(AppColors.secondaryArgb, 0xFF007A4D);
  });
}
