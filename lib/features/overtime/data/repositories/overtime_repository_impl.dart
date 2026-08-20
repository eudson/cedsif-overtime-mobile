import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import 'package:cedsif_overtime_mobile/core/error/failures.dart';
import 'package:cedsif_overtime_mobile/features/overtime/data/datasources/overtime_local_datasource.dart';
import 'package:cedsif_overtime_mobile/features/overtime/data/datasources/overtime_pending_request_datasource.dart';
import 'package:cedsif_overtime_mobile/features/overtime/data/datasources/overtime_remote_datasource.dart';
import 'package:cedsif_overtime_mobile/features/overtime/data/models/time_entry_model.dart';
import 'package:cedsif_overtime_mobile/features/overtime/domain/entities/device_location.dart';
import 'package:cedsif_overtime_mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:cedsif_overtime_mobile/features/overtime/domain/repositories/overtime_repository.dart';

typedef OvertimeIdFactory = String Function();
typedef OvertimeSyncTrigger = void Function();

class OvertimeRepositoryImpl implements OvertimeRepository {
  const OvertimeRepositoryImpl(
    this._dataSource, {
    required OvertimeRemoteDataSource remoteDataSource,
    required OvertimePendingRequestDataSource pendingDataSource,
    required OvertimeIdFactory idFactory,
    required OvertimeSyncTrigger triggerSync,
  }) : _pendingDataSource = pendingDataSource,
       _remoteDataSource = remoteDataSource,
       _idFactory = idFactory,
       _triggerSync = triggerSync;

  final OvertimeLocalDataSource _dataSource;
  final OvertimePendingRequestDataSource _pendingDataSource;
  final OvertimeRemoteDataSource _remoteDataSource;
  final OvertimeIdFactory _idFactory;
  final OvertimeSyncTrigger _triggerSync;

  @override
  Future<Either<Failure, OvertimeSnapshot>> load() async {
    try {
      final localActive = await _dataSource.loadActiveSession();
      final localHistory = await _dataSource.loadHistory();
      try {
        final remoteEntries = await _remoteDataSource.history();
        return Right(
          await _synchronize(remoteEntries, localActive, localHistory),
        );
      } on DioException {
        return Right(
          OvertimeSnapshot(activeSession: localActive, history: localHistory),
        );
      }
    } on _OvertimeReconciliationConflict {
      return const Left(ValidationFailure('overtime.conflictingActiveSession'));
    } on Object {
      return const Left(CacheFailure('errors.generic'));
    }
  }

  Future<OvertimeSnapshot> _synchronize(
    List<TimeEntryModel> remoteEntries,
    OvertimeSession? localActive,
    List<OvertimeSession> localHistory,
  ) async {
    OvertimeSession? remoteActive;
    final remoteHistory = <OvertimeSession>[];
    for (final model in remoteEntries) {
      final session = _fromRemote(model);
      if (session.status == OvertimeSessionStatus.active) {
        remoteActive = session;
      } else {
        remoteHistory.add(session);
      }
    }

    final remoteIds = remoteEntries.map((entry) => entry.id).toSet();
    final localHasPendingWrites =
        remoteActive != null &&
        localActive != null &&
        remoteActive.id != localActive.id &&
        await _pendingDataSource.hasPendingForTimeEntry(localActive.id);
    if (localHasPendingWrites) {
      throw const _OvertimeReconciliationConflict();
    }
    final mergedHistory = <OvertimeSession>[
      ...localHistory.where((entry) => !remoteIds.contains(entry.id)),
      ...remoteHistory,
    ];
    final history = await _dataSource.replaceHistory(mergedHistory);
    final active = switch ((remoteActive, localActive)) {
      (final server?, final local?) when server.id == local.id => local,
      (final server?, _) => server,
      (null, final local?) when !remoteIds.contains(local.id) => local,
      _ => null,
    };
    if (active != null && active != localActive) {
      await _dataSource.saveActiveSession(active);
    } else if (active == null && localActive != null) {
      await _dataSource.clearActiveSession();
    }
    return OvertimeSnapshot(activeSession: active, history: history);
  }

  OvertimeSession _fromRemote(TimeEntryModel model) => OvertimeSession(
    id: model.id,
    startedAt: model.startedAt,
    endedAt: model.endedAt,
    status: switch (model.status) {
      'IN_PROGRESS' => OvertimeSessionStatus.active,
      'CLOSED' || 'SENT' => OvertimeSessionStatus.pending,
      _ => throw FormatException('Unsupported overtime status ${model.status}'),
    },
  );

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

class _OvertimeReconciliationConflict implements Exception {
  const _OvertimeReconciliationConflict();
}
