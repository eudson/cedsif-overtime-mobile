import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cedsif_overtime_mobile/core/error/failures.dart';
import 'package:cedsif_overtime_mobile/features/overtime/data/datasources/overtime_local_datasource.dart';
import 'package:cedsif_overtime_mobile/features/overtime/data/datasources/overtime_pending_request_datasource.dart';
import 'package:cedsif_overtime_mobile/features/overtime/data/repositories/overtime_repository_impl.dart';
import 'package:cedsif_overtime_mobile/features/overtime/domain/entities/device_location.dart';
import 'package:cedsif_overtime_mobile/features/overtime/domain/entities/overtime_session.dart';

class _MockDataSource extends Mock implements OvertimeLocalDataSource {}

class _MockPendingDataSource extends Mock
    implements OvertimePendingRequestDataSource {}

class _FakeOvertimeSession extends Fake implements OvertimeSession {}

void main() {
  late _MockDataSource dataSource;
  late _MockPendingDataSource pendingDataSource;
  late OvertimeRepositoryImpl repository;
  late List<String> ids;

  setUpAll(() => registerFallbackValue(_FakeOvertimeSession()));

  setUp(() {
    dataSource = _MockDataSource();
    pendingDataSource = _MockPendingDataSource();
    ids = <String>['entry-1', 'start-1', 'end-1', 'submit-1'];
    repository = OvertimeRepositoryImpl(
      dataSource,
      pendingDataSource: pendingDataSource,
      idFactory: () => ids.removeAt(0),
      triggerSync: () {},
    );
  });

  test('loads active and completed sessions as one snapshot', () async {
    final active = OvertimeSession(
      id: 'active',
      startedAt: DateTime(2026, 8, 13, 8),
      status: OvertimeSessionStatus.active,
    );
    when(dataSource.loadActiveSession).thenAnswer((_) async => active);
    when(dataSource.loadHistory).thenAnswer((_) async => const []);

    final result = await repository.load();

    expect(
      result,
      Right<Failure, OvertimeSnapshot>(
        OvertimeSnapshot(activeSession: active, history: const []),
      ),
    );
  });

  test('maps Hive errors to a cache failure', () async {
    when(dataSource.loadActiveSession).thenThrow(StateError('broken cache'));

    final result = await repository.load();

    expect(result.isLeft(), isTrue);
    expect(result.getLeft().toNullable(), isA<CacheFailure>());
  });

  test(
    'start persists identifiers and queues biometric location proof',
    () async {
      final startedAt = DateTime.utc(2026, 8, 20, 9);
      final location = DeviceLocation(
        latitude: -25.9692,
        longitude: 32.5732,
        accuracyMeters: 4,
        capturedAt: startedAt,
      );
      when(dataSource.loadActiveSession).thenAnswer((_) async => null);
      when(() => dataSource.saveActiveSession(any())).thenAnswer((_) async {});
      when(
        () => pendingDataSource.enqueueStart(
          timeEntryId: any(named: 'timeEntryId'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          biometricReference: any(named: 'biometricReference'),
          startedAt: any(named: 'startedAt'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenAnswer((_) async {});

      final result = await repository.start(
        startedAt: startedAt,
        location: location,
        biometricReference: 'face-1',
      );

      final session = result.getRight().toNullable();
      expect(session?.id, 'entry-1');
      expect(session?.startIdempotencyKey, 'start-1');
      expect(session?.endIdempotencyKey, 'end-1');
      expect(session?.submitIdempotencyKey, 'submit-1');
      verify(
        () => pendingDataSource.enqueueStart(
          timeEntryId: 'entry-1',
          latitude: -25.9692,
          longitude: 32.5732,
          biometricReference: 'face-1',
          startedAt: startedAt,
          idempotencyKey: 'start-1',
        ),
      ).called(1);
      verify(() => dataSource.saveActiveSession(session!)).called(1);
    },
  );

  test('pause persists a reviewing session without adding history', () async {
    final active = OvertimeSession(
      id: 'active',
      startedAt: DateTime(2026, 8, 14, 8),
      status: OvertimeSessionStatus.active,
    );
    final pausedAt = DateTime(2026, 8, 14, 9);
    when(dataSource.loadActiveSession).thenAnswer((_) async => active);
    when(() => dataSource.saveActiveSession(any())).thenAnswer((_) async {});

    final result = await repository.pause(pausedAt);

    final reviewing = result.getRight().toNullable();
    expect(reviewing?.status, OvertimeSessionStatus.reviewing);
    expect(reviewing?.endedAt, pausedAt);
    verify(() => dataSource.saveActiveSession(reviewing!)).called(1);
    verifyNever(() => dataSource.prependHistory(any()));
  });

  test('resume persists the review period as paused time', () async {
    final reviewing = OvertimeSession(
      id: 'active',
      startedAt: DateTime(2026, 8, 14, 8),
      endedAt: DateTime(2026, 8, 14, 9),
      status: OvertimeSessionStatus.reviewing,
    );
    when(dataSource.loadActiveSession).thenAnswer((_) async => reviewing);
    when(() => dataSource.saveActiveSession(any())).thenAnswer((_) async {});

    final result = await repository.resume(DateTime(2026, 8, 14, 9, 20));

    final resumed = result.getRight().toNullable();
    expect(resumed?.status, OvertimeSessionStatus.active);
    expect(resumed?.pausedDuration, const Duration(minutes: 20));
    verify(() => dataSource.saveActiveSession(resumed!)).called(1);
  });

  test('submit moves the reviewing session into pending history', () async {
    final reviewing = OvertimeSession(
      id: 'active',
      startedAt: DateTime(2026, 8, 14, 8),
      endedAt: DateTime(2026, 8, 14, 9),
      status: OvertimeSessionStatus.reviewing,
      startIdempotencyKey: 'start-1',
      endIdempotencyKey: 'end-1',
      submitIdempotencyKey: 'submit-1',
    );
    final pending = reviewing.submit();
    when(dataSource.loadActiveSession).thenAnswer((_) async => reviewing);
    when(
      () => dataSource.prependHistory(pending),
    ).thenAnswer((_) async => [pending]);
    when(dataSource.clearActiveSession).thenAnswer((_) async {});
    when(
      () => pendingDataSource.enqueueEnd(
        timeEntryId: any(named: 'timeEntryId'),
        endedAt: any(named: 'endedAt'),
        idempotencyKey: any(named: 'idempotencyKey'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => pendingDataSource.enqueueSubmit(
        workDate: any(named: 'workDate'),
        idempotencyKey: any(named: 'idempotencyKey'),
      ),
    ).thenAnswer((_) async {});

    final result = await repository.submit();

    final snapshot = result.getRight().toNullable();
    expect(snapshot?.activeSession, isNull);
    expect(snapshot?.history, [pending]);
    verifyInOrder(<void Function()>[
      () => pendingDataSource.enqueueEnd(
        timeEntryId: 'active',
        endedAt: DateTime(2026, 8, 14, 9),
        idempotencyKey: 'end-1',
      ),
      () => pendingDataSource.enqueueSubmit(
        workDate: DateTime(2026, 8, 14, 8),
        idempotencyKey: 'submit-1',
      ),
    ]);
    verify(dataSource.clearActiveSession).called(1);
  });
}
