import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cedsif_overtime_mobile/core/error/failures.dart';
import 'package:cedsif_overtime_mobile/features/overtime/data/datasources/overtime_local_datasource.dart';
import 'package:cedsif_overtime_mobile/features/overtime/data/repositories/overtime_repository_impl.dart';
import 'package:cedsif_overtime_mobile/features/overtime/domain/entities/overtime_session.dart';

class _MockDataSource extends Mock implements OvertimeLocalDataSource {}

class _FakeOvertimeSession extends Fake implements OvertimeSession {}

void main() {
  late _MockDataSource dataSource;
  late OvertimeRepositoryImpl repository;

  setUpAll(() => registerFallbackValue(_FakeOvertimeSession()));

  setUp(() {
    dataSource = _MockDataSource();
    repository = OvertimeRepositoryImpl(dataSource);
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
    );
    final pending = reviewing.submit();
    when(dataSource.loadActiveSession).thenAnswer((_) async => reviewing);
    when(
      () => dataSource.prependHistory(pending),
    ).thenAnswer((_) async => [pending]);
    when(dataSource.clearActiveSession).thenAnswer((_) async {});

    final result = await repository.submit();

    final snapshot = result.getRight().toNullable();
    expect(snapshot?.activeSession, isNull);
    expect(snapshot?.history, [pending]);
    verify(dataSource.clearActiveSession).called(1);
  });
}
