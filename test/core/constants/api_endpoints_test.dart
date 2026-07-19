import 'package:flutter_test/flutter_test.dart';

import 'package:cedsif_overtime_mobile/core/constants/api_endpoints.dart';

void main() {
  test('API endpoints are relative, rooted, and distinct', () {
    const endpoints = [ApiEndpoints.health, ApiEndpoints.refreshToken];
    expect(endpoints.toSet(), hasLength(endpoints.length));
    for (final endpoint in endpoints) {
      expect(endpoint, startsWith('/'));
      expect(Uri.tryParse(endpoint)?.hasScheme, isFalse);
    }
  });
}
