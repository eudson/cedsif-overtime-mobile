import 'package:hive/hive.dart';

import 'package:cedsif_overtime_mobile/core/constants/api_endpoints.dart';
import 'package:cedsif_overtime_mobile/core/sync/pending_request_model.dart';

typedef PendingRequestClock = DateTime Function();
typedef PendingRequestOwnerSubjectProvider = Future<String?> Function();

class OvertimePendingRequestDataSource {
  OvertimePendingRequestDataSource(
    this._box, {
    required PendingRequestOwnerSubjectProvider ownerSubjectProvider,
    PendingRequestClock? clock,
  }) : _ownerSubjectProvider = ownerSubjectProvider,
       _clock = clock ?? DateTime.now;

  final Box<dynamic> _box;
  final PendingRequestOwnerSubjectProvider _ownerSubjectProvider;
  final PendingRequestClock _clock;

  Future<void> enqueueStart({
    required String timeEntryId,
    required double latitude,
    required double longitude,
    required String biometricReference,
    required DateTime startedAt,
    required String idempotencyKey,
  }) => _enqueue(
    path: ApiEndpoints.overtimeStart,
    idempotencyKey: idempotencyKey,
    body: <String, Object?>{
      'timeEntryId': timeEntryId,
      'latitude': latitude,
      'longitude': longitude,
      'biometricReference': biometricReference,
      'startedAt': startedAt.toUtc().toIso8601String(),
    },
  );

  Future<void> enqueueEnd({
    required String timeEntryId,
    required DateTime endedAt,
    required String idempotencyKey,
  }) => _enqueue(
    path: ApiEndpoints.overtimeEnd,
    idempotencyKey: idempotencyKey,
    body: <String, Object?>{
      'timeEntryId': timeEntryId,
      'endedAt': endedAt.toUtc().toIso8601String(),
    },
  );

  Future<void> enqueueSubmit({
    required DateTime workDate,
    required String idempotencyKey,
  }) => _enqueue(
    path: ApiEndpoints.overtimeSubmit,
    idempotencyKey: idempotencyKey,
    body: <String, Object?>{'workDate': _formatDate(workDate)},
  );

  Future<void> _enqueue({
    required String path,
    required String idempotencyKey,
    required Map<String, Object?> body,
  }) async {
    if (_box.containsKey(idempotencyKey)) {
      return;
    }
    final ownerSubject = await _ownerSubjectProvider();
    if (ownerSubject == null || ownerSubject.isEmpty) {
      throw StateError('Authenticated employee subject is unavailable');
    }
    final request = PendingRequestModel(
      method: 'POST',
      path: path,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Idempotency-Key': idempotencyKey,
      },
      body: body,
      createdAt: _clock().toUtc(),
      retryCount: 0,
    );
    await _box.put(idempotencyKey, <String, Object?>{
      ...request.toJson(),
      'ownerSubject': ownerSubject,
    });
  }

  static String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
