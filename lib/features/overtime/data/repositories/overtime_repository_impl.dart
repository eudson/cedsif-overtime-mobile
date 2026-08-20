import 'package:fpdart/fpdart.dart';

import 'package:cedsif_overtime_mobile/core/error/failures.dart';
import 'package:cedsif_overtime_mobile/features/overtime/data/datasources/overtime_local_datasource.dart';
import 'package:cedsif_overtime_mobile/features/overtime/data/datasources/overtime_pending_request_datasource.dart';
import 'package:cedsif_overtime_mobile/features/overtime/domain/entities/device_location.dart';
import 'package:cedsif_overtime_mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:cedsif_overtime_mobile/features/overtime/domain/repositories/overtime_repository.dart';

typedef OvertimeIdFactory = String Function();
typedef OvertimeSyncTrigger = void Function();

class OvertimeRepositoryImpl implements OvertimeRepository {
  const OvertimeRepositoryImpl(
    this._dataSource, {
    required OvertimePendingRequestDataSource pendingDataSource,
    required OvertimeIdFactory idFactory,
    required OvertimeSyncTrigger triggerSync,
  }) : _pendingDataSource = pendingDataSource,
       _idFactory = idFactory,
       _triggerSync = triggerSync;

  final OvertimeLocalDataSource _dataSource;
  final OvertimePendingRequestDataSource _pendingDataSource;
  final OvertimeIdFactory _idFactory;
  final OvertimeSyncTrigger _triggerSync;

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
  Future<Either<Failure, OvertimeSession>> start({
    required DateTime startedAt,
    required DeviceLocation location,
    required String biometricReference,
  }) async {
    try {
      final current = await _dataSource.loadActiveSession();
      if (current != null) {
        return Right(current);
      }
      final session = OvertimeSession(
        id: _idFactory(),
        startedAt: startedAt,
        status: OvertimeSessionStatus.active,
        startIdempotencyKey: _idFactory(),
        endIdempotencyKey: _idFactory(),
        submitIdempotencyKey: _idFactory(),
      );
      await _pendingDataSource.enqueueStart(
        timeEntryId: session.id,
        latitude: location.latitude,
        longitude: location.longitude,
        biometricReference: biometricReference,
        startedAt: startedAt,
        idempotencyKey: session.startIdempotencyKey!,
      );
      await _dataSource.saveActiveSession(session);
      _triggerSync();
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
      final endIdempotencyKey = reviewing.endIdempotencyKey ?? _idFactory();
      final submitIdempotencyKey =
          reviewing.submitIdempotencyKey ?? _idFactory();
      await _pendingDataSource.enqueueEnd(
        timeEntryId: reviewing.id,
        endedAt: reviewing.endedAt!,
        idempotencyKey: endIdempotencyKey,
      );
      await _pendingDataSource.enqueueSubmit(
        workDate: reviewing.startedAt,
        idempotencyKey: submitIdempotencyKey,
      );
      final history = await _dataSource.prependHistory(completed);
      await _dataSource.clearActiveSession();
      _triggerSync();
      return Right(OvertimeSnapshot(history: history));
    } on Object {
      return const Left(CacheFailure('errors.generic'));
    }
  }
}
