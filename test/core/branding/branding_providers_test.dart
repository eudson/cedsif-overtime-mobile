import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cedsif_overtime_mobile/core/branding/branding_config.dart';
import 'package:cedsif_overtime_mobile/core/branding/branding_providers.dart';
import 'package:cedsif_overtime_mobile/core/constants/app_colors.dart';

void main() {
  test('theme providers react to an overridden branding configuration', () {
    final container = ProviderContainer(
      overrides: [
        brandingConfigProvider.overrideWithValue(
          const BrandingConfig(primaryColor: AppColors.error),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(lightThemeProvider).colorScheme.primary,
      AppColors.error,
    );
    expect(
      container.read(darkThemeProvider).colorScheme.primary,
      AppColors.error,
    );
  });
}
