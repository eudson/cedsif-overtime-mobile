import 'package:flutter_test/flutter_test.dart';

import 'package:cedsif_overtime_mobile/core/sync/pending_request_model.dart';

void main() {
  test('round-trips the generic pending request JSON payload', () {
    final createdAt = DateTime.utc(2026, 7, 19, 12, 30);
    final model = PendingRequestModel(
      method: 'POST',
      path: '/resource',
      headers: const <String, String>{'content-type': 'application/json'},
      body: const <String, Object?>{'value': 1},
      createdAt: createdAt,
      retryCount: 2,
    );

    expect(PendingRequestModel.fromJson(model.toJson()), model);
  });
}
