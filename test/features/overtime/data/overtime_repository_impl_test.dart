import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cedsif_overtime_mobile/core/error/failures.dart';
import 'package:cedsif_overtime_mobile/features/overtime/data/datasources/overtime_local_datasource.dart';
import 'package:cedsif_overtime_mobile/features/overtime/data/repositories/overtime_repository_impl.dart';
import 'package:cedsif_overtime_mobile/features/overtime/domain/entities/overtime_session.dart';

class _MockDataSource extends Mock implements OvertimeLocalDataSource {}

void main() {
  late _MockDataSource dataSource;
  late OvertimeRepositoryImpl repository;

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
}
