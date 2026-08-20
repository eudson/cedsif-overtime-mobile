import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cedsif_overtime_mobile/core/constants/api_endpoints.dart';
import 'package:cedsif_overtime_mobile/core/sync/pending_request_timestamp_migration.dart';

class _MockBox extends Mock implements Box<dynamic> {}

void main() {
  test('adds UTC offsets to existing queued overtime timestamps', () async {
    final box = _MockBox();
    final start = <String, Object?>{
      'method': 'POST',
      'path': ApiEndpoints.overtimeStart,
      'body': <String, Object?>{
        'timeEntryId': 'entry-1',
        'startedAt': '2026-08-20T19:37:37.155793',
      },
      'retryCount': 4,
    };
    final end = <String, Object?>{
      'method': 'POST',
      'path': ApiEndpoints.overtimeEnd,
      'body': <String, Object?>{
        'timeEntryId': 'entry-1',
        'endedAt': '2026-08-20T19:40:18.488453',
      },
      'retryCount': 0,
    };
    when(
      () => box.toMap(),
    ).thenReturn(<dynamic, dynamic>{'start-key': start, 'end-key': end});
    when(
      () => box.put(any<dynamic>(), any<dynamic>()),
    ).thenAnswer((_) async {});

    await PendingRequestTimestampMigration(box).migrate();

    final expectedStart = DateTime.parse(
      '2026-08-20T19:37:37.155793',
    ).toUtc().toIso8601String();
    final expectedEnd = DateTime.parse(
      '2026-08-20T19:40:18.488453',
    ).toUtc().toIso8601String();
    verify(
      () => box.put('start-key', <String, Object?>{
        ...start,
        PendingRequestTimestampMigration.legacyOwnerResolutionAttemptedKey:
            true,
        'body': <String, Object?>{
          'timeEntryId': 'entry-1',
          'startedAt': expectedStart,
        },
      }),
    ).called(1);
    verify(
      () => box.put('end-key', <String, Object?>{
        ...end,
        PendingRequestTimestampMigration.legacyOwnerResolutionAttemptedKey:
            true,
        'body': <String, Object?>{
          'timeEntryId': 'entry-1',
          'endedAt': expectedEnd,
        },
      }),
    ).called(1);
  });

  test('leaves offset-aware and unrelated requests unchanged', () async {
    final box = _MockBox();
    when(() => box.toMap()).thenReturn(<dynamic, dynamic>{
      'start-key': <String, Object?>{
        'path': ApiEndpoints.overtimeStart,
        'ownerSubject': 'employee-1',
        'body': <String, Object?>{'startedAt': '2026-08-20T17:37:37Z'},
      },
      'submit-key': <String, Object?>{
        'path': ApiEndpoints.overtimeSubmit,
        'ownerSubject': 'employee-1',
        'body': <String, Object?>{'workDate': '2026-08-20'},
      },
    });

    await PendingRequestTimestampMigration(box).migrate();

    verifyNever(() => box.put(any<dynamic>(), any<dynamic>()));
  });

  test(
    'binds every legacy request to the proven stored-token subject',
    () async {
      final box = _MockBox();
      const start = <String, Object?>{
        'path': ApiEndpoints.overtimeStart,
        'body': <String, Object?>{'startedAt': '2026-08-20T17:37:37Z'},
      };
      const submit = <String, Object?>{
        'path': ApiEndpoints.overtimeSubmit,
        'body': <String, Object?>{'workDate': '2026-08-20'},
      };
      when(() => box.toMap()).thenReturn(<dynamic, dynamic>{
        'start-key': start,
        'submit-key': submit,
      });
      when(
        () => box.put(any<dynamic>(), any<dynamic>()),
      ).thenAnswer((_) async {});

      await PendingRequestTimestampMigration(
        box,
      ).migrate(legacyOwnerSubject: 'employee-1');

      verify(
        () => box.put('start-key', <String, Object?>{
          ...start,
          'ownerSubject': 'employee-1',
        }),
      ).called(1);
      verify(
        () => box.put('submit-key', <String, Object?>{
          ...submit,
          'ownerSubject': 'employee-1',
        }),
      ).called(1);
    },
  );

  test('quarantines ownership when no stored-token subject exists', () async {
    final box = _MockBox();
    const request = <String, Object?>{'path': ApiEndpoints.overtimeSubmit};
    when(
      () => box.toMap(),
    ).thenReturn(<dynamic, dynamic>{'submit-key': request});
    when(
      () => box.put(any<dynamic>(), any<dynamic>()),
    ).thenAnswer((_) async {});

    await PendingRequestTimestampMigration(box).migrate();

    verify(
      () => box.put('submit-key', <String, Object?>{
        ...request,
        PendingRequestTimestampMigration.legacyOwnerResolutionAttemptedKey:
            true,
      }),
    ).called(1);
  });

  test('never assigns a later subject to a quarantined request', () async {
    final box = _MockBox();
    const request = <String, Object?>{
      'path': ApiEndpoints.overtimeSubmit,
      PendingRequestTimestampMigration.legacyOwnerResolutionAttemptedKey: true,
    };
    when(
      () => box.toMap(),
    ).thenReturn(<dynamic, dynamic>{'submit-key': request});

    await PendingRequestTimestampMigration(
      box,
    ).migrate(legacyOwnerSubject: 'employee-2');

    verifyNever(() => box.put(any<dynamic>(), any<dynamic>()));
  });

  test(
    'fails initialization when ownership quarantine cannot persist',
    () async {
      final box = _MockBox();
      when(() => box.toMap()).thenReturn(<dynamic, dynamic>{
        'submit-key': <String, Object?>{'path': ApiEndpoints.overtimeSubmit},
      });
      when(
        () => box.put(any<dynamic>(), any<dynamic>()),
      ).thenThrow(StateError('disk unavailable'));

      await expectLater(
        PendingRequestTimestampMigration(box).migrate(),
        throwsA(isA<StateError>()),
      );
    },
  );
}
