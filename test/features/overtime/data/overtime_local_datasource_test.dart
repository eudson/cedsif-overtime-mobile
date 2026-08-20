import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cedsif_overtime_mobile/features/overtime/data/datasources/overtime_local_datasource.dart';
import 'package:cedsif_overtime_mobile/features/overtime/domain/entities/overtime_session.dart';

class _MockBox extends Mock implements Box<dynamic> {}

void main() {
  late _MockBox box;
  late OvertimeLocalDataSource dataSource;

  setUp(() {
    box = _MockBox();
    dataSource = OvertimeLocalDataSource(box);
  });

  test('uses feature-owned keys without demo prefixes', () {
    expect(OvertimeLocalDataSource.activeSessionKey, 'active_session');
    expect(OvertimeLocalDataSource.historyKey, 'history');
  });

  test('loads the active session from a JSON-compatible Hive map', () async {
    when(() => box.get(OvertimeLocalDataSource.activeSessionKey)).thenReturn({
      'id': 'active-1',
      'startedAt': '2026-08-13T08:24:00.000',
      'endedAt': null,
      'status': 'active',
      'startIdempotencyKey': 'start-1',
      'endIdempotencyKey': 'end-1',
      'submitIdempotencyKey': 'submit-1',
    });

    expect(
      await dataSource.loadActiveSession(),
      OvertimeSession(
        id: 'active-1',
        startedAt: DateTime(2026, 8, 13, 8, 24),
        status: OvertimeSessionStatus.active,
        startIdempotencyKey: 'start-1',
        endIdempotencyKey: 'end-1',
        submitIdempotencyKey: 'submit-1',
      ),
    );
  });

  test('persists and clears the active session', () async {
    final session = OvertimeSession(
      id: 'active-1',
      startedAt: DateTime(2026, 8, 13, 8, 24),
      status: OvertimeSessionStatus.active,
      startIdempotencyKey: 'start-1',
      endIdempotencyKey: 'end-1',
      submitIdempotencyKey: 'submit-1',
    );
    when(
      () => box.put(OvertimeLocalDataSource.activeSessionKey, any<dynamic>()),
    ).thenAnswer((_) async {});
    when(
      () => box.delete(OvertimeLocalDataSource.activeSessionKey),
    ).thenAnswer((_) async {});

    await dataSource.saveActiveSession(session);
    await dataSource.clearActiveSession();

    verify(
      () => box.put(OvertimeLocalDataSource.activeSessionKey, {
        'id': 'active-1',
        'startedAt': '2026-08-13T08:24:00.000',
        'endedAt': null,
        'status': 'active',
        'pausedDurationSeconds': 0,
        'startIdempotencyKey': 'start-1',
        'endIdempotencyKey': 'end-1',
        'submitIdempotencyKey': 'submit-1',
      }),
    ).called(1);
    verify(
      () => box.delete(OvertimeLocalDataSource.activeSessionKey),
    ).called(1);
  });

  test('restores a reviewing session and its accumulated pause time', () async {
    when(() => box.get(OvertimeLocalDataSource.activeSessionKey)).thenReturn({
      'id': 'reviewing-1',
      'startedAt': '2026-08-13T08:24:00.000',
      'endedAt': '2026-08-13T09:24:00.000',
      'status': 'reviewing',
      'pausedDurationSeconds': 900,
    });

    final session = await dataSource.loadActiveSession();

    expect(session?.status, OvertimeSessionStatus.reviewing);
    expect(session?.pausedDuration, const Duration(minutes: 15));
    expect(
      session?.durationAt(DateTime(2026, 8, 13, 12)),
      const Duration(minutes: 45),
    );
  });

  test('returns empty history when no synchronized records exist', () async {
    when(() => box.get(OvertimeLocalDataSource.historyKey)).thenReturn(null);

    final history = await dataSource.loadHistory();

    expect(history, isEmpty);
    verifyNever(
      () => box.put(OvertimeLocalDataSource.historyKey, any<dynamic>()),
    );
  });

  test('prepends a completed session to persisted history', () async {
    when(() => box.get(OvertimeLocalDataSource.historyKey)).thenReturn([
      {
        'id': 'older',
        'startedAt': '2026-07-18T08:24:00.000',
        'endedAt': '2026-07-18T11:11:00.000',
        'status': 'pending',
      },
    ]);
    when(
      () => box.put(OvertimeLocalDataSource.historyKey, any<dynamic>()),
    ).thenAnswer((_) async {});
    final latest = OvertimeSession(
      id: 'latest',
      startedAt: DateTime(2026, 8, 13, 9),
      endedAt: DateTime(2026, 8, 13, 10),
      status: OvertimeSessionStatus.pending,
    );

    final history = await dataSource.prependHistory(latest);

    expect(history.map((entry) => entry.id), ['latest', 'older']);
    final saved =
        verify(
              () => box.put(
                OvertimeLocalDataSource.historyKey,
                captureAny<dynamic>(),
              ),
            ).captured.single
            as List<dynamic>;
    expect((saved.first as Map<dynamic, dynamic>)['id'], 'latest');
  });

  test(
    'replaces a session with the same id instead of duplicating it',
    () async {
      when(() => box.get(OvertimeLocalDataSource.historyKey)).thenReturn([
        {
          'id': 'same-session',
          'startedAt': '2026-08-13T09:00:00.000',
          'endedAt': '2026-08-13T10:00:00.000',
          'status': 'pending',
        },
      ]);
      when(
        () => box.put(OvertimeLocalDataSource.historyKey, any<dynamic>()),
      ).thenAnswer((_) async {});
      final retry = OvertimeSession(
        id: 'same-session',
        startedAt: DateTime(2026, 8, 13, 9),
        endedAt: DateTime(2026, 8, 13, 10),
        status: OvertimeSessionStatus.pending,
      );

      final history = await dataSource.prependHistory(retry);

      expect(history, [retry]);
    },
  );
}
