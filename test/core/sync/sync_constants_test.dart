import 'package:flutter_test/flutter_test.dart';

import 'package:cedsif_overtime_mobile/core/sync/sync_constants.dart';

void main() {
  test('uses the minimum supported periodic work interval', () {
    expect(SyncConstants.frequency, const Duration(minutes: 15));
  });

  test('uses stable generic worker identifiers', () {
    expect(SyncConstants.uniqueWorkName, 'background_sync');
    expect(SyncConstants.taskName, 'sync_pending_requests');
  });
}
