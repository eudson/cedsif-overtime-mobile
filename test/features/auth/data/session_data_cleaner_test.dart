import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cedsif_overtime_mobile/features/auth/data/services/session_data_cleaner.dart';

class _MockBox extends Mock implements Box<dynamic> {}

void main() {
  test('clears session data without deleting queued requests', () async {
    final cache = _MockBox();
    final pending = _MockBox();
    final overtime = _MockBox();
    for (final box in <_MockBox>[cache, pending, overtime]) {
      when(box.clear).thenAnswer((_) async => 1);
    }

    await LocalSessionDataCleaner(
      cacheBox: cache,
      overtimeBox: overtime,
    ).clear();

    verify(cache.clear).called(1);
    verifyNever(pending.clear);
    verify(overtime.clear).called(1);
  });
}
