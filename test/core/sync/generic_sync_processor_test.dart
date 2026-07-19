import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cedsif_overtime_mobile/core/sync/generic_sync_processor.dart';

class _MockBox extends Mock implements Box<dynamic> {}

class _MockPendingRequestHandler extends Mock
    implements PendingRequestHandler {}

class _BlockingPendingRequestHandler implements PendingRequestHandler {
  final Completer<void> release = Completer<void>();
  int calls = 0;

  @override
  Future<bool> process(Map<String, Object?> request) async {
    calls += 1;
    await release.future;
    return true;
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
      'headers': <String, Object?>{'Idempotency-Key': 'request-1'},
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
        'headers': <String, Object?>{'Idempotency-Key': 'request-1'},
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
    final handler = DioPendingRequestHandler(dio);

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
    });

    expect(result, isTrue);
    expect(adapter.request?.method, 'PATCH');
    expect(adapter.request?.path, '/generic-resource');
    expect(adapter.request?.headers['Authorization'], isNull);
    expect(adapter.request?.headers['Cookie'], isNull);
    expect(adapter.request?.headers['Content-Type'], 'application/json');
    expect(adapter.request?.headers['Idempotency-Key'], 'stable-request-key');
  });

  test('Dio handler rejects cross-origin absolute paths', () async {
    final adapter = _RecordingAdapter(200);
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = adapter;

    final result = await DioPendingRequestHandler(dio).process(
      <String, Object?>{
        'method': 'GET',
        'path': 'https://attacker.example/items',
      },
    );

    expect(result, isFalse);
    expect(adapter.request, isNull);
  });

  test('Dio handler requires idempotency key for unsafe methods', () async {
    final adapter = _RecordingAdapter(200);
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = adapter;

    final result = await DioPendingRequestHandler(
      dio,
    ).process(<String, Object?>{'method': 'POST', 'path': '/items'});

    expect(result, isFalse);
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
    when(() => handler.process(request)).thenAnswer((_) async => true);
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
      final handler = DioPendingRequestHandler(dio);

      expect(
        await handler.process(<String, Object?>{
          'method': 'POST',
          'path': '/generic-resource',
        }),
        isFalse,
      );
      expect(
        await handler.process(<String, Object?>{'method': 'POST'}),
        isFalse,
      );
    },
  );
}
