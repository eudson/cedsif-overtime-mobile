import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cedsif_overtime_mobile/core/sync/generic_sync_processor.dart';

class _MockBox extends Mock implements Box<dynamic> {}

class _MockPendingRequestHandler extends Mock
    implements PendingRequestHandler {}

void main() {
  late _MockBox queue;
  late _MockPendingRequestHandler handler;

  setUp(() {
    queue = _MockBox();
    handler = _MockPendingRequestHandler();
  });

  test('removes requests only after the handler succeeds', () async {
    const request = <String, Object?>{'method': 'POST', 'path': '/resource'};
    when(
      () => queue.toMap(),
    ).thenReturn(<dynamic, dynamic>{'request-1': request});
    when(() => handler.process(request)).thenAnswer((_) async => true);
    when(() => queue.delete('request-1')).thenAnswer((_) async {});

    final result = await GenericSyncProcessor(
      pendingRequestsBox: queue,
      handler: handler,
    ).processPendingRequests();

    expect(result, isTrue);
    verify(() => queue.delete('request-1')).called(1);
  });

  test('retains requests when the handler requests a retry', () async {
    const request = <String, Object?>{
      'method': 'POST',
      'path': '/resource',
      'retryCount': 2,
    };
    when(
      () => queue.toMap(),
    ).thenReturn(<dynamic, dynamic>{'request-1': request});
    when(() => handler.process(request)).thenAnswer((_) async => false);
    when(() => queue.put('request-1', any<dynamic>())).thenAnswer((_) async {});

    final result = await GenericSyncProcessor(
      pendingRequestsBox: queue,
      handler: handler,
    ).processPendingRequests();

    expect(result, isFalse);
    verifyNever(() => queue.delete(any<dynamic>()));
    verify(
      () => queue.put('request-1', <String, Object?>{
        'method': 'POST',
        'path': '/resource',
        'retryCount': 3,
      }),
    ).called(1);
  });

  test(
    'retains requests and reports failure when the handler throws',
    () async {
      const request = <String, Object?>{
        'method': 'POST',
        'path': '/resource',
        'retryCount': 0,
      };
      when(
        () => queue.toMap(),
      ).thenReturn(<dynamic, dynamic>{'request-1': request});
      when(
        () => handler.process(request),
      ).thenThrow(StateError('transport failed'));
      when(
        () => queue.put('request-1', any<dynamic>()),
      ).thenAnswer((_) async {});

      final result = await GenericSyncProcessor(
        pendingRequestsBox: queue,
        handler: handler,
      ).processPendingRequests();

      expect(result, isFalse);
      verifyNever(() => queue.delete(any<dynamic>()));
      verify(
        () => queue.put('request-1', <String, Object?>{
          'method': 'POST',
          'path': '/resource',
          'retryCount': 1,
        }),
      ).called(1);
    },
  );

  test('rejects malformed queue entries without invoking transport', () async {
    when(
      () => queue.toMap(),
    ).thenReturn(<dynamic, dynamic>{'request-1': 'invalid'});

    final result = await GenericSyncProcessor(
      pendingRequestsBox: queue,
      handler: handler,
    ).processPendingRequests();

    expect(result, isFalse);
    verifyNever(() => handler.process(any()));
  });
}
