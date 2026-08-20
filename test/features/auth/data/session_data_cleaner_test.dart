import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cedsif_overtime_mobile/features/auth/data/services/session_data_cleaner.dart';

class _MockBox extends Mock implements Box<dynamic> {}

class _DelayedCleaner implements SessionDataCleaner {
  final firstClear = Completer<void>();
  int calls = 0;

  @override
  Future<void> clear() async {
    calls++;
    if (calls == 1) {
      await firstClear.future;
    }
  }

  @override
  Future<void> claimSubject(String subject) async {}
}

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

  test(
    'preserves a reviewing session when the same user reauthenticates',
    () async {
      final cache = _MockBox();
      final overtime = _MockBox();
      when(
        () => overtime.get(LocalSessionDataCleaner.ownerSubjectKey),
      ).thenReturn('employee-1');

      await LocalSessionDataCleaner(
        cacheBox: cache,
        overtimeBox: overtime,
      ).claimSubject('employee-1');

      verifyNever(cache.clear);
      verifyNever(overtime.clear);
      verifyNever(() => overtime.put(any<dynamic>(), any<dynamic>()));
    },
  );

  test(
    'preserves reviewing state after refresh expiry clears the generic cache',
    () async {
      final cache = _MockBox();
      final overtime = _MockBox();
      when(cache.clear).thenAnswer((_) async => 1);
      when(
        () => overtime.get(LocalSessionDataCleaner.ownerSubjectKey),
      ).thenReturn('employee-1');

      await cache.clear();
      await LocalSessionDataCleaner(
        cacheBox: cache,
        overtimeBox: overtime,
      ).claimSubject('employee-1');

      verify(cache.clear).called(1);
      verifyNever(overtime.clear);
      verifyNever(() => overtime.put(any<dynamic>(), any<dynamic>()));
    },
  );

  test(
    'clears prior user snapshots before assigning a different user',
    () async {
      final cache = _MockBox();
      final overtime = _MockBox();
      when(
        () => overtime.get(LocalSessionDataCleaner.ownerSubjectKey),
      ).thenReturn('employee-1');
      when(cache.clear).thenAnswer((_) async => 1);
      when(overtime.clear).thenAnswer((_) async => 1);
      when(
        () =>
            overtime.put(LocalSessionDataCleaner.ownerSubjectKey, 'employee-2'),
      ).thenAnswer((_) async {});

      await LocalSessionDataCleaner(
        cacheBox: cache,
        overtimeBox: overtime,
      ).claimSubject('employee-2');

      verify(cache.clear).called(1);
      verify(overtime.clear).called(1);
      verify(
        () =>
            overtime.put(LocalSessionDataCleaner.ownerSubjectKey, 'employee-2'),
      ).called(1);
    },
  );

  test('serializes overlapping session cleanup operations', () async {
    final cleaner = _DelayedCleaner();
    final coordinator = SessionDataResetCoordinator(cleaner);

    final expiryCleanup = coordinator.clear();
    final loginCleanup = coordinator.clear();
    await Future<void>.delayed(Duration.zero);

    expect(cleaner.calls, 1);
    cleaner.firstClear.complete();
    await Future.wait([expiryCleanup, loginCleanup]);
    expect(cleaner.calls, 2);
  });
}
