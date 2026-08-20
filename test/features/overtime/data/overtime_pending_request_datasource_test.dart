import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cedsif_overtime_mobile/core/constants/api_endpoints.dart';
import 'package:cedsif_overtime_mobile/features/overtime/data/datasources/overtime_pending_request_datasource.dart';

class _MockBox extends Mock implements Box<dynamic> {}

void main() {
  late _MockBox box;
  late OvertimePendingRequestDataSource dataSource;
  final createdAt = DateTime.utc(2026, 8, 20, 12);

  setUp(() {
    box = _MockBox();
    dataSource = OvertimePendingRequestDataSource(
      box,
      ownerSubjectProvider: () async => 'employee-1',
      clock: () => createdAt,
    );
    when(() => box.containsKey(any<dynamic>())).thenReturn(false);
    when(
      () => box.put(any<dynamic>(), any<dynamic>()),
    ).thenAnswer((_) async {});
  });

  test('queues start with the exact API contract', () async {
    final startedAt = DateTime(2026, 8, 20, 9, 15);

    await dataSource.enqueueStart(
      timeEntryId: 'entry-1',
      latitude: -25.9692,
      longitude: 32.5732,
      biometricReference: 'face-1',
      startedAt: startedAt,
      idempotencyKey: 'start-1',
    );

    verify(
      () => box.put('start-1', <String, Object?>{
        'method': 'POST',
        'path': ApiEndpoints.overtimeStart,
        'headers': <String, String>{
          'Content-Type': 'application/json',
          'Idempotency-Key': 'start-1',
        },
        'body': <String, Object?>{
          'timeEntryId': 'entry-1',
          'latitude': -25.9692,
          'longitude': 32.5732,
          'biometricReference': 'face-1',
          'startedAt': startedAt.toUtc().toIso8601String(),
        },
        'createdAt': createdAt.toIso8601String(),
        'retryCount': 0,
        'ownerSubject': 'employee-1',
      }),
    ).called(1);
  });

  test('queues end followed by daily submission contracts', () async {
    final endedAt = DateTime(2026, 8, 20, 11, 45);

    await dataSource.enqueueEnd(
      timeEntryId: 'entry-1',
      endedAt: endedAt,
      idempotencyKey: 'end-1',
    );
    await dataSource.enqueueSubmit(
      workDate: endedAt,
      idempotencyKey: 'submit-1',
    );

    final writes = verifyInOrder(<void Function()>[
      () => box.put('end-1', captureAny<dynamic>()),
      () => box.put('submit-1', captureAny<dynamic>()),
    ]);
    final submit = writes[1].captured.single as Map<dynamic, dynamic>;
    final end = writes[0].captured.single as Map<dynamic, dynamic>;
    expect(
      (end['body'] as Map<dynamic, dynamic>)['endedAt'],
      endedAt.toUtc().toIso8601String(),
    );
    expect(submit['path'], ApiEndpoints.overtimeSubmit);
    expect(submit['body'], <String, Object?>{'workDate': '2026-08-20'});
  });

  test('does not replace an existing request with the same key', () async {
    when(() => box.containsKey('start-1')).thenReturn(true);

    await dataSource.enqueueStart(
      timeEntryId: 'entry-1',
      latitude: 0,
      longitude: 0,
      biometricReference: 'face-1',
      startedAt: createdAt,
      idempotencyKey: 'start-1',
    );

    verifyNever(() => box.put(any<dynamic>(), any<dynamic>()));
  });

  test('finds queued writes for a specific time entry', () async {
    when(() => box.values).thenReturn(<dynamic>[
      <String, Object?>{
        'body': <String, Object?>{'timeEntryId': 'entry-1'},
      },
      <String, Object?>{
        'body': <String, Object?>{'workDate': '2026-08-20'},
      },
    ]);

    expect(await dataSource.hasPendingForTimeEntry('entry-1'), isTrue);
    expect(await dataSource.hasPendingForTimeEntry('entry-2'), isFalse);
  });

  test('does not queue work without an authenticated owner', () async {
    final unownedDataSource = OvertimePendingRequestDataSource(
      box,
      ownerSubjectProvider: () async => null,
      clock: () => createdAt,
    );

    await expectLater(
      unownedDataSource.enqueueStart(
        timeEntryId: 'entry-1',
        latitude: 0,
        longitude: 0,
        biometricReference: 'face-1',
        startedAt: createdAt,
        idempotencyKey: 'start-1',
      ),
      throwsStateError,
    );

    verifyNever(() => box.put(any<dynamic>(), any<dynamic>()));
  });
}
