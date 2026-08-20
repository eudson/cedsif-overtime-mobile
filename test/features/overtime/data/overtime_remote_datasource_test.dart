import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cedsif_overtime_mobile/core/constants/api_endpoints.dart';
import 'package:cedsif_overtime_mobile/features/overtime/data/datasources/overtime_remote_datasource.dart';

class _RecordingAdapter implements HttpClientAdapter {
  RequestOptions? request;
  Object? responseBody;
  int statusCode = 200;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      jsonEncode(responseBody),
      statusCode,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  const entryId = '6b7d9ca6-b437-41e8-8be4-521792aec978';
  const workUnitId = '07cde809-5634-45cc-8653-34f76ba54dc8';
  const idempotencyKey = '2d06bc79-6d8e-4ddf-a75b-e0b1432e038d';
  final startedAt = DateTime.parse('2026-08-20T16:00:00+02:00');

  test(
    'starts overtime with the client entry id and idempotency key',
    () async {
      final adapter = _RecordingAdapter()
        ..statusCode = 201
        ..responseBody = <String, Object?>{
          'id': entryId,
          'workUnitId': workUnitId,
          'status': 'IN_PROGRESS',
          'startedAt': '2026-08-20T14:00:00Z',
          'locationVerified': true,
        };
      final dataSource = DioOvertimeRemoteDataSource(
        Dio()..httpClientAdapter = adapter,
      );

      final entry = await dataSource.start(
        timeEntryId: entryId,
        latitude: -25.9681,
        longitude: 32.5732,
        biometricReference: 'SIMULATED-entry-1',
        startedAt: startedAt,
        idempotencyKey: idempotencyKey,
      );

      expect(adapter.request?.path, ApiEndpoints.overtimeStart);
      expect(adapter.request?.method, 'POST');
      expect(adapter.request?.headers['Idempotency-Key'], idempotencyKey);
      expect(adapter.request?.data, <String, Object?>{
        'timeEntryId': entryId,
        'latitude': -25.9681,
        'longitude': 32.5732,
        'biometricReference': 'SIMULATED-entry-1',
        'startedAt': startedAt.toIso8601String(),
      });
      expect(entry.id, entryId);
      expect(entry.status, 'IN_PROGRESS');
      expect(entry.locationVerified, isTrue);
    },
  );

  test('ends overtime with the entry id and idempotency key', () async {
    final endedAt = DateTime.parse('2026-08-20T18:00:00+02:00');
    final adapter = _RecordingAdapter()
      ..responseBody = <String, Object?>{
        'id': entryId,
        'workUnitId': workUnitId,
        'status': 'CLOSED',
        'startedAt': '2026-08-20T14:00:00Z',
        'endedAt': '2026-08-20T16:00:00Z',
        'durationSeconds': 7200,
        'locationVerified': true,
      };
    final dataSource = DioOvertimeRemoteDataSource(
      Dio()..httpClientAdapter = adapter,
    );

    final entry = await dataSource.end(
      timeEntryId: entryId,
      endedAt: endedAt,
      idempotencyKey: idempotencyKey,
    );

    expect(adapter.request?.path, ApiEndpoints.overtimeEnd);
    expect(adapter.request?.headers['Idempotency-Key'], idempotencyKey);
    expect(adapter.request?.data, <String, Object?>{
      'timeEntryId': entryId,
      'endedAt': endedAt.toIso8601String(),
    });
    expect(entry.durationSeconds, 7200);
    expect(entry.status, 'CLOSED');
  });

  test('loads and parses overtime history', () async {
    final adapter = _RecordingAdapter()
      ..responseBody = <Object?>[
        <String, Object?>{
          'id': entryId,
          'workUnitId': workUnitId,
          'status': 'CLOSED',
          'startedAt': '2026-08-20T14:00:00Z',
          'endedAt': '2026-08-20T16:00:00Z',
          'durationSeconds': 7200,
          'locationVerified': false,
        },
      ];
    final dataSource = DioOvertimeRemoteDataSource(
      Dio()..httpClientAdapter = adapter,
    );

    final history = await dataSource.history();

    expect(adapter.request?.path, ApiEndpoints.overtimeHistory);
    expect(adapter.request?.method, 'GET');
    expect(history, hasLength(1));
    expect(history.single.id, entryId);
    expect(history.single.locationVerified, isFalse);
  });

  test('submits a work day with a stable idempotency key', () async {
    const submissionId = 'f7b9f7db-5252-4523-a3d1-08773bf8eb51';
    final adapter = _RecordingAdapter()
      ..statusCode = 202
      ..responseBody = <String, Object?>{
        'id': submissionId,
        'workDate': '2026-08-20',
        'status': 'QUEUED',
        'entryCount': 1,
        'totalDurationSeconds': 7200,
      };
    final dataSource = DioOvertimeRemoteDataSource(
      Dio()..httpClientAdapter = adapter,
    );

    final submission = await dataSource.submit(
      workDate: DateTime(2026, 8, 20),
      idempotencyKey: idempotencyKey,
    );

    expect(adapter.request?.path, ApiEndpoints.overtimeSubmit);
    expect(adapter.request?.headers['Idempotency-Key'], idempotencyKey);
    expect(adapter.request?.data, <String, Object?>{'workDate': '2026-08-20'});
    expect(submission.id, submissionId);
    expect(submission.status, 'QUEUED');
    expect(submission.totalDurationSeconds, 7200);
  });

  test('rejects malformed overtime response data', () async {
    final adapter = _RecordingAdapter()
      ..statusCode = 201
      ..responseBody = <String, Object?>{'id': entryId};
    final dataSource = DioOvertimeRemoteDataSource(
      Dio()..httpClientAdapter = adapter,
    );

    await expectLater(
      dataSource.start(
        timeEntryId: entryId,
        latitude: -25.9681,
        longitude: 32.5732,
        biometricReference: 'SIMULATED-entry-1',
        startedAt: startedAt,
        idempotencyKey: idempotencyKey,
      ),
      throwsA(isA<FormatException>()),
    );
  });
}
