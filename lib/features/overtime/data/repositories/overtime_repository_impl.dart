import 'package:fpdart/fpdart.dart';

import 'package:cedsif_overtime_mobile/core/error/failures.dart';
import 'package:cedsif_overtime_mobile/features/overtime/data/datasources/overtime_local_datasource.dart';
import 'package:cedsif_overtime_mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:cedsif_overtime_mobile/features/overtime/domain/repositories/overtime_repository.dart';

class OvertimeRepositoryImpl implements OvertimeRepository {
  const OvertimeRepositoryImpl(this._dataSource);

  final OvertimeLocalDataSource _dataSource;

  @override
  Future<Either<Failure, OvertimeSnapshot>> load() async {
    try {
      return Right(
        OvertimeSnapshot(
          activeSession: await _dataSource.loadActiveSession(),
          history: await _dataSource.loadHistory(),
        ),
      );
    } on Object {
      return const Left(CacheFailure('errors.generic'));
    }
  }

  @override
  Future<Either<Failure, OvertimeSession>> start(DateTime startedAt) async {
    try {
      final current = await _dataSource.loadActiveSession();
      if (current != null) {
        return Right(current);
      }
      final session = OvertimeSession(
        id: 'session-${startedAt.microsecondsSinceEpoch}',
        startedAt: startedAt,
        status: OvertimeSessionStatus.active,
      );
      await _dataSource.saveActiveSession(session);
      return Right(session);
    } on Object {
      return const Left(CacheFailure('errors.generic'));
    }
  }

  @override
  Future<Either<Failure, OvertimeSession>> pause(DateTime pausedAt) async {
    try {
      final active = await _dataSource.loadActiveSession();
      if (active == null) {
        return const Left(CacheFailure('errors.generic'));
      }
      final reviewing = active.pauseAt(pausedAt);
      await _dataSource.saveActiveSession(reviewing);
      return Right(reviewing);
    } on Object {
      return const Left(CacheFailure('errors.generic'));
    }
  }

  @override
  Future<Either<Failure, OvertimeSession>> resume(DateTime resumedAt) async {
    try {
      final reviewing = await _dataSource.loadActiveSession();
      if (reviewing == null) {
        return const Left(CacheFailure('errors.generic'));
      }
      final resumed = reviewing.resumeAt(resumedAt);
      await _dataSource.saveActiveSession(resumed);
      return Right(resumed);
    } on Object {
      return const Left(CacheFailure('errors.generic'));
    }
  }

  @override
  Future<Either<Failure, OvertimeSnapshot>> submit() async {
    try {
      final reviewing = await _dataSource.loadActiveSession();
      if (reviewing == null) {
        return Right(
          OvertimeSnapshot(history: await _dataSource.loadHistory()),
        );
      }
      final completed = reviewing.submit();
      final history = await _dataSource.prependHistory(completed);
      await _dataSource.clearActiveSession();
      return Right(OvertimeSnapshot(history: history));
    } on Object {
      return const Left(CacheFailure('errors.generic'));
    }
  }
}
