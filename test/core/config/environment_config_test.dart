import 'package:flutter_test/flutter_test.dart';

import 'package:cedsif_overtime_mobile/core/config/environment_config.dart';
import 'package:cedsif_overtime_mobile/core/constants/constants.dart';

void main() {
  group('EnvironmentConfig parsing', () {
    test('parses known environments case-insensitively', () {
      expect(
        EnvironmentConfig.parseEnvironment('PROD'),
        AppEnvironment.production,
      );
      expect(
        EnvironmentConfig.parseEnvironment('staging'),
        AppEnvironment.staging,
      );
      expect(
        EnvironmentConfig.parseEnvironment(''),
        AppEnvironment.development,
      );
    });

    test('parses a positive timeout and falls back for invalid input', () {
      expect(
        EnvironmentConfig.parseTimeout('15000'),
        const Duration(seconds: 15),
      );
      expect(
        EnvironmentConfig.parseTimeout('-1'),
        AppConstants.defaultApiTimeout,
      );
      expect(
        EnvironmentConfig.parseTimeout('nope'),
        AppConstants.defaultApiTimeout,
      );
    });
  });
}
