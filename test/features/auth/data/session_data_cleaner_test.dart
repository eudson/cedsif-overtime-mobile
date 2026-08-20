import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cedsif_overtime_mobile/features/auth/data/services/session_data_cleaner.dart';

class _MockBox extends Mock implements Box<dynamic> {}

void main() {
  test('clears cache, queued requests, and overtime records', () async {
    final cache = _MockBox();
    final pending = _MockBox();
    final overtime = _MockBox();
    for (final box in <_MockBox>[cache, pending, overtime]) {
      when(box.clear).thenAnswer((_) async => 1);
    }

    await LocalSessionDataCleaner(
      cacheBox: cache,
      pendingRequestsBox: pending,
      overtimeBox: overtime,
    ).clear();

    verify(cache.clear).called(1);
    verify(pending.clear).called(1);
    verify(overtime.clear).called(1);
  });
}
