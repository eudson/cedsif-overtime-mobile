import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cedsif_overtime_mobile/core/auth/authenticated_subject.dart';
import 'package:cedsif_overtime_mobile/core/sync/generic_sync_processor.dart';

class _MockBox extends Mock implements Box<dynamic> {}

class _MockPendingRequestHandler extends Mock
    implements PendingRequestHandler {}

class _BlockingPendingRequestHandler implements PendingRequestHandler {
  final Completer<void> release = Completer<void>();
  int calls = 0;

  @override
  Future<PendingRequestOutcome> process(Map<String, Object?> request) async {
    calls += 1;
    await release.future;
    return PendingRequestOutcome.success;
  }
}

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.statusCode);

  final int statusCode;
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      jsonEncode(<String, Object?>{'ok': statusCode < 300}),
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
  late _MockBox queue;
  late _MockPendingRequestHandler handler;

  setUp(() {
    queue = _MockBox();
    handler = _MockPendingRequestHandler();
  });

  test('removes requests only after the handler succeeds', () async {
    const request = <String, Object?>{
      'method': 'POST',
      'path': '/resource',
      'headers': <String, Object?>{'Idempotency-Key': 'request-1'},
    };
    when(
      () => queue.toMap(),
    ).thenReturn(<dynamic, dynamic>{'request-1': request});
    when(
      () => handler.process(request),
    ).thenAnswer((_) async => PendingRequestOutcome.success);
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
      'headers': <String, Object?>{'Idempotency-Key': 'request-1'},
      'retryCount': 2,
    };
    when(
      () => queue.toMap(),
    ).thenReturn(<dynamic, dynamic>{'request-1': request});
    when(
      () => handler.process(request),
    ).thenAnswer((_) async => PendingRequestOutcome.retry);
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
        'headers': <String, Object?>{'Idempotency-Key': 'request-1'},
        'retryCount': 3,
      }),
    ).called(1);
  });

  test('stops the FIFO pass after the first retry', () async {
    const first = <String, Object?>{
      'method': 'POST',
      'path': '/first',
      'headers': <String, Object?>{'Idempotency-Key': 'first'},
      'retryCount': 0,
    };
    const second = <String, Object?>{
      'method': 'POST',
      'path': '/second',
      'headers': <String, Object?>{'Idempotency-Key': 'second'},
      'retryCount': 0,
    };
    when(
      () => queue.toMap(),
    ).thenReturn(<dynamic, dynamic>{'first': first, 'second': second});
    when(
      () => handler.process(first),
    ).thenAnswer((_) async => PendingRequestOutcome.retry);
    when(() => queue.put('first', any<dynamic>())).thenAnswer((_) async {});

    final result = await GenericSyncProcessor(
      pendingRequestsBox: queue,
      handler: handler,
    ).processPendingRequests();

    expect(result, isFalse);
    verify(() => handler.process(first)).called(1);
    verifyNever(() => handler.process(second));
  });

  test('processes queued requests by createdAt instead of box order', () async {
    const start = <String, Object?>{
      'method': 'POST',
      'path': '/start',
      'headers': <String, Object?>{'Idempotency-Key': 'start'},
      'createdAt': '2026-08-20T17:37:49Z',
    };
    const end = <String, Object?>{
      'method': 'POST',
      'path': '/end',
      'headers': <String, Object?>{'Idempotency-Key': 'end'},
      'createdAt': '2026-08-20T17:40:20Z',
    };
    const submit = <String, Object?>{
      'method': 'POST',
      'path': '/submit',
      'headers': <String, Object?>{'Idempotency-Key': 'submit'},
      'createdAt': '2026-08-20T17:40:21Z',
    };
    when(() => queue.toMap()).thenReturn(<dynamic, dynamic>{
      'submit': submit,
      'start': start,
      'end': end,
    });
    for (final request in <Map<String, Object?>>[start, end, submit]) {
      when(
        () => handler.process(request),
      ).thenAnswer((_) async => PendingRequestOutcome.success);
    }
    when(() => queue.delete(any<dynamic>())).thenAnswer((_) async {});

    final result = await GenericSyncProcessor(
      pendingRequestsBox: queue,
      handler: handler,
    ).processPendingRequests();

    expect(result, isTrue);
    verifyInOrder(<void Function()>[
      () => handler.process(start),
      () => handler.process(end),
      () => handler.process(submit),
    ]);
  });

  test(
    'retains requests and reports failure when the handler throws',
    () async {
      const request = <String, Object?>{
        'method': 'POST',
        'path': '/resource',
        'headers': <String, Object?>{'Idempotency-Key': 'request-1'},
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
          'headers': <String, Object?>{'Idempotency-Key': 'request-1'},
          'retryCount': 1,
        }),
      ).called(1);
    },
  );

  test('rejects malformed queue entries without invoking transport', () async {
    when(
      () => queue.toMap(),
    ).thenReturn(<dynamic, dynamic>{'request-1': 'invalid'});
    when(() => queue.delete('request-1')).thenAnswer((_) async {});

    final result = await GenericSyncProcessor(
      pendingRequestsBox: queue,
      handler: handler,
    ).processPendingRequests();

    expect(result, isFalse);
    verifyNever(() => handler.process(any()));
    verify(() => queue.delete('request-1')).called(1);
  });

  test('Dio handler replays generic request and ignores stored auth', () async {
    final adapter = _RecordingAdapter(204);
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = adapter;
    final handler = DioPendingRequestHandler(
      dio,
      authenticatedTokenProvider: () async => const AuthenticatedToken(
        accessToken: 'fresh-token',
        subject: 'employee-1',
      ),
    );

    final result = await handler.process(<String, Object?>{
      'method': 'PATCH',
      'path': '/generic-resource',
      'headers': <String, Object?>{
        'Authorization': 'Bearer stale-secret',
        'Cookie': 'session=stale-secret',
        'Content-Type': 'application/json',
        'Idempotency-Key': 'stable-request-key',
      },
      'body': <String, Object?>{'value': 1},
      'ownerSubject': 'employee-1',
    });

    expect(result, PendingRequestOutcome.success);
    expect(adapter.request?.method, 'PATCH');
    expect(adapter.request?.path, '/generic-resource');
    expect(adapter.request?.headers['Authorization'], 'Bearer fresh-token');
    expect(adapter.request?.headers['Cookie'], isNull);
    expect(adapter.request?.headers['Content-Type'], 'application/json');
    expect(adapter.request?.headers['Idempotency-Key'], 'stable-request-key');
  });

  test('Dio handler rejects cross-origin absolute paths', () async {
    final adapter = _RecordingAdapter(200);
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = adapter;

    final result =
        await DioPendingRequestHandler(
          dio,
          authenticatedTokenProvider: () async => const AuthenticatedToken(
            accessToken: 'fresh-token',
            subject: 'employee-1',
          ),
        ).process(<String, Object?>{
          'method': 'GET',
          'path': 'https://attacker.example/items',
          'ownerSubject': 'employee-1',
        });

    expect(result, PendingRequestOutcome.permanentRejection);
    expect(adapter.request, isNull);
  });

  test('Dio handler requires idempotency key for unsafe methods', () async {
    final adapter = _RecordingAdapter(200);
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = adapter;

    final result =
        await DioPendingRequestHandler(
          dio,
          authenticatedTokenProvider: () async => const AuthenticatedToken(
            accessToken: 'fresh-token',
            subject: 'employee-1',
          ),
        ).process(<String, Object?>{
          'method': 'POST',
          'path': '/items',
          'ownerSubject': 'employee-1',
        });

    expect(result, PendingRequestOutcome.permanentRejection);
    expect(adapter.request, isNull);
  });

  test('overlapping processor invocations share one queue pass', () async {
    const request = <String, Object?>{'method': 'GET', 'path': '/resource'};
    when(
      () => queue.toMap(),
    ).thenReturn(<dynamic, dynamic>{'request-1': request});
    when(() => queue.delete('request-1')).thenAnswer((_) async {});
    final blockingHandler = _BlockingPendingRequestHandler();
    final processor = GenericSyncProcessor(
      pendingRequestsBox: queue,
      handler: blockingHandler,
    );

    final first = processor.processPendingRequests();
    final second = processor.processPendingRequests();
    await Future<void>.delayed(Duration.zero);
    expect(blockingHandler.calls, 1);
    blockingHandler.release.complete();

    expect(await Future.wait(<Future<bool>>[first, second]), <bool>[
      true,
      true,
    ]);
    expect(blockingHandler.calls, 1);
  });

  test('delete failure retains stable idempotency key for retry', () async {
    const request = <String, Object?>{
      'method': 'POST',
      'path': '/resource',
      'headers': <String, Object?>{'Idempotency-Key': 'stable-key'},
      'retryCount': 0,
    };
    when(
      () => queue.toMap(),
    ).thenReturn(<dynamic, dynamic>{'request-1': request});
    when(
      () => handler.process(request),
    ).thenAnswer((_) async => PendingRequestOutcome.success);
    when(
      () => queue.delete('request-1'),
    ).thenThrow(StateError('delete failed'));
    when(() => queue.put('request-1', any<dynamic>())).thenAnswer((_) async {});

    final result = await GenericSyncProcessor(
      pendingRequestsBox: queue,
      handler: handler,
    ).processPendingRequests();

    expect(result, isFalse);
    verify(
      () => queue.put('request-1', <String, Object?>{
        ...request,
        'retryCount': 1,
      }),
    ).called(1);
  });

  test(
    'Dio handler reports non-2xx and malformed requests as failures',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..httpClientAdapter = _RecordingAdapter(500);
      final handler = DioPendingRequestHandler(
        dio,
        authenticatedTokenProvider: () async => const AuthenticatedToken(
          accessToken: 'fresh-token',
          subject: 'employee-1',
        ),
      );

      expect(
        await handler.process(<String, Object?>{
          'method': 'POST',
          'path': '/generic-resource',
          'ownerSubject': 'employee-1',
        }),
        PendingRequestOutcome.permanentRejection,
      );
      expect(
        await handler.process(<String, Object?>{
          'method': 'POST',
          'ownerSubject': 'employee-1',
        }),
        PendingRequestOutcome.permanentRejection,
      );
    },
  );

  test('Dio handler rejects whitespace-only idempotency keys', () async {
    final adapter = _RecordingAdapter(200);
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = adapter;

    final result =
        await DioPendingRequestHandler(
          dio,
          authenticatedTokenProvider: () async => const AuthenticatedToken(
            accessToken: 'fresh-token',
            subject: 'employee-1',
          ),
        ).process(<String, Object?>{
          'method': 'POST',
          'path': '/items',
          'headers': <String, Object?>{'Idempotency-Key': '   '},
          'ownerSubject': 'employee-1',
        });

    expect(result, PendingRequestOutcome.permanentRejection);
    expect(adapter.request, isNull);
  });

  test('Dio handler retains requests owned by another employee', () async {
    final adapter = _RecordingAdapter(200);
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = adapter;

    final result =
        await DioPendingRequestHandler(
          dio,
          authenticatedTokenProvider: () async => const AuthenticatedToken(
            accessToken: 'employee-2-token',
            subject: 'employee-2',
          ),
        ).process(<String, Object?>{
          'method': 'POST',
          'path': '/items',
          'headers': <String, Object?>{'Idempotency-Key': 'request-1'},
          'ownerSubject': 'employee-1',
        });

    expect(result, PendingRequestOutcome.deferred);
    expect(adapter.request, isNull);
  });

  test('processor deletes a permanently rejected queued request', () async {
    const request = <String, Object?>{'method': 'GET', 'path': '/resource'};
    when(
      () => queue.toMap(),
    ).thenReturn(<dynamic, dynamic>{'request-1': request});
    when(
      () => handler.process(request),
    ).thenAnswer((_) async => PendingRequestOutcome.permanentRejection);
    when(() => queue.delete('request-1')).thenAnswer((_) async {});

    final result = await GenericSyncProcessor(
      pendingRequestsBox: queue,
      handler: handler,
    ).processPendingRequests();

    expect(result, isFalse);
    verify(() => queue.delete('request-1')).called(1);
    verifyNever(() => queue.put(any<dynamic>(), any<dynamic>()));
  });

  test('deferred request does not block a later owned request', () async {
    const deferredRequest = <String, Object?>{
      'method': 'GET',
      'path': '/first',
    };
    const ownedRequest = <String, Object?>{'method': 'GET', 'path': '/second'};
    when(() => queue.toMap()).thenReturn(<dynamic, dynamic>{
      'request-1': deferredRequest,
      'request-2': ownedRequest,
    });
    when(
      () => handler.process(deferredRequest),
    ).thenAnswer((_) async => PendingRequestOutcome.deferred);
    when(
      () => handler.process(ownedRequest),
    ).thenAnswer((_) async => PendingRequestOutcome.success);
    when(() => queue.delete('request-2')).thenAnswer((_) async {});

    final result = await GenericSyncProcessor(
      pendingRequestsBox: queue,
      handler: handler,
    ).processPendingRequests();

    expect(result, isFalse);
    verify(() => handler.process(deferredRequest)).called(1);
    verify(() => handler.process(ownedRequest)).called(1);
    verifyNever(() => queue.delete('request-1'));
    verify(() => queue.delete('request-2')).called(1);
    verifyNever(() => queue.put(any<dynamic>(), any<dynamic>()));
  });
}
