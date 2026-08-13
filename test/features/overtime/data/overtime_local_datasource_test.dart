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

  test('loads the active session from a JSON-compatible Hive map', () async {
    when(() => box.get(OvertimeLocalDataSource.activeSessionKey)).thenReturn({
      'id': 'active-1',
      'startedAt': '2026-08-13T08:24:00.000',
      'endedAt': null,
      'status': 'active',
    });

    expect(
      await dataSource.loadActiveSession(),
      OvertimeSession(
        id: 'active-1',
        startedAt: DateTime(2026, 8, 13, 8, 24),
        status: OvertimeSessionStatus.active,
      ),
    );
  });

  test('persists and clears the active session', () async {
    final session = OvertimeSession(
      id: 'active-1',
      startedAt: DateTime(2026, 8, 13, 8, 24),
      status: OvertimeSessionStatus.active,
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
      }),
    ).called(1);
    verify(
      () => box.delete(OvertimeLocalDataSource.activeSessionKey),
    ).called(1);
  });

  test('seeds reference history once and keeps newest records first', () async {
    when(() => box.get(OvertimeLocalDataSource.historyKey)).thenReturn(null);
    when(
      () => box.put(OvertimeLocalDataSource.historyKey, any<dynamic>()),
    ).thenAnswer((_) async {});

    final history = await dataSource.loadHistory();

    expect(history, hasLength(4));
    expect(history.first.status, OvertimeSessionStatus.pending);
    expect(history.first.startedAt, DateTime(2026, 7, 18, 8, 24));
    verify(
      () => box.put(OvertimeLocalDataSource.historyKey, any<dynamic>()),
    ).called(1);
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
}
