import 'package:flutter_test/flutter_test.dart';

import 'package:cedsif_overtime_mobile/core/constants/api_endpoints.dart';
import 'package:cedsif_overtime_mobile/core/constants/constants.dart';

void main() {
  test('API endpoints are relative, rooted, and distinct', () {
    const endpoints = [
      ApiEndpoints.health,
      ApiEndpoints.login,
      ApiEndpoints.refreshToken,
    ];
    expect(endpoints.toSet(), hasLength(endpoints.length));
    for (final endpoint in endpoints) {
      expect(endpoint, startsWith('/'));
      expect(Uri.tryParse(endpoint)?.hasScheme, isFalse);
    }
  });

  test('cache TTL is centralized and positive', () {
    expect(AppConstants.cacheTtl, const Duration(minutes: 15));
    expect(AppConstants.cacheTtl, greaterThan(Duration.zero));
  });
}
