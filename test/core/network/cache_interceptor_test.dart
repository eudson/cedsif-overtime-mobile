import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cedsif_overtime_mobile/core/network/cache_interceptor.dart';
import 'package:cedsif_overtime_mobile/core/network/network_monitor.dart';

class _MockBox extends Mock implements Box<dynamic> {}

class _MockNetworkMonitor extends Mock implements NetworkMonitor {}

class _RequestHandler extends Mock implements RequestInterceptorHandler {}

class _ResponseHandler extends Mock implements ResponseInterceptorHandler {}

void main() {
  late _MockBox box;
  late _MockNetworkMonitor monitor;
  late CacheInterceptor interceptor;

  setUpAll(() {
    registerFallbackValue(
      Response<dynamic>(requestOptions: RequestOptions(path: '/fallback')),
    );
  });

  setUp(() {
    box = _MockBox();
    monitor = _MockNetworkMonitor();
    interceptor = CacheInterceptor(
      cacheBox: box,
      networkMonitor: monitor,
      scopeProvider: () async => 'scope-a',
      now: () => DateTime.utc(2026, 1, 1),
    );
  });

  test('offline GET resolves a cached successful response', () async {
    final request = RequestOptions(
      baseUrl: 'https://example.test',
      path: '/items',
      method: 'GET',
      headers: <String, Object?>{'Authorization': 'Bearer secret'},
    );
    final key = CacheInterceptor.cacheKey(request, scope: 'scope-a');
    when(() => monitor.isOnline).thenAnswer((_) async => false);
    when(() => box.get(key)).thenReturn(<String, Object?>{
      'data': <String, Object?>{'ok': true},
      'statusCode': 200,
      'scope': 'scope-a',
      'storedAt': DateTime.utc(2026, 1, 1).millisecondsSinceEpoch,
      'version': 1,
    });
    final handler = _RequestHandler();

    await interceptor.onRequest(request, handler);

    final response =
        verify(() => handler.resolve(captureAny())).captured.single
            as Response<dynamic>;
    expect(response.data, <String, Object?>{'ok': true});
    expect(response.statusCode, 200);
  });

  test('cache key does not change with authorization credentials', () {
    final first = RequestOptions(
      path: '/items',
      method: 'GET',
      headers: <String, Object?>{'Authorization': 'Bearer first'},
    );
    final second = RequestOptions(
      path: '/items',
      method: 'GET',
      headers: <String, Object?>{'authorization': 'Bearer second'},
    );

    expect(
      CacheInterceptor.cacheKey(first, scope: 'scope-a'),
      CacheInterceptor.cacheKey(second, scope: 'scope-a'),
    );
    expect(
      CacheInterceptor.cacheKey(first, scope: 'scope-a'),
      isNot(contains('first')),
    );
  });

  test('ignores malformed offline cache entries', () async {
    final request = RequestOptions(path: '/items', method: 'GET');
    when(() => monitor.isOnline).thenAnswer((_) async => false);
    when(
      () => box.get(CacheInterceptor.cacheKey(request, scope: 'scope-a')),
    ).thenReturn(<Object?, Object?>{1: 'invalid'});
    final handler = _RequestHandler();

    await interceptor.onRequest(request, handler);

    verify(() => handler.next(request)).called(1);
    verifyNever(() => handler.resolve(any()));
  });

  test('caches only successful GET responses', () async {
    final getRequest = RequestOptions(path: '/items', method: 'GET');
    final response = Response<dynamic>(
      requestOptions: getRequest,
      data: <String, Object?>{'ok': true},
      statusCode: 200,
    );
    final key = CacheInterceptor.cacheKey(getRequest, scope: 'scope-a');
    final cached = <String, Object?>{
      'data': <String, Object?>{'ok': true},
      'statusCode': 200,
      'scope': 'scope-a',
      'storedAt': DateTime.utc(2026, 1, 1).millisecondsSinceEpoch,
      'version': 1,
    };
    when(() => box.put(key, cached)).thenAnswer((_) async {});
    final handler = _ResponseHandler();

    await interceptor.onResponse(response, handler);

    verify(() => box.put(key, cached)).called(1);
    verify(() => handler.next(response)).called(1);
  });

  test('never caches unsafe write responses', () async {
    final request = RequestOptions(path: '/items', method: 'POST');
    final response = Response<dynamic>(
      requestOptions: request,
      data: <String, Object?>{'secret': true},
      statusCode: 201,
    );
    final handler = _ResponseHandler();

    await interceptor.onResponse(response, handler);

    verifyNever(() => box.put(any<dynamic>(), any<dynamic>()));
    verify(() => handler.next(response)).called(1);
  });

  test('cache storage failure does not discard a network response', () async {
    final request = RequestOptions(path: '/items', method: 'GET');
    final response = Response<dynamic>(
      requestOptions: request,
      data: <String, Object?>{'ok': true},
      statusCode: 200,
    );
    final key = CacheInterceptor.cacheKey(request, scope: 'scope-a');
    final cached = <String, Object?>{
      'data': <String, Object?>{'ok': true},
      'statusCode': 200,
      'scope': 'scope-a',
      'storedAt': DateTime.utc(2026, 1, 1).millisecondsSinceEpoch,
      'version': 1,
    };
    when(() => box.put(key, cached)).thenThrow(StateError('cache unavailable'));
    final handler = _ResponseHandler();

    await interceptor.onResponse(response, handler);

    verify(() => handler.next(response)).called(1);
  });

  test('does not serve an expired cache entry', () async {
    final request = RequestOptions(path: '/items', method: 'GET');
    final key = CacheInterceptor.cacheKey(request, scope: 'scope-a');
    when(() => monitor.isOnline).thenAnswer((_) async => false);
    when(() => box.get(key)).thenReturn(<String, Object?>{
      'data': 'stale',
      'statusCode': 200,
      'scope': 'scope-a',
      'storedAt': DateTime.utc(2025, 12, 31).millisecondsSinceEpoch,
      'version': 1,
    });
    when(() => box.delete(key)).thenAnswer((_) async {});
    final handler = _RequestHandler();

    await interceptor.onRequest(request, handler);

    verify(() => handler.next(request)).called(1);
    verify(() => box.delete(key)).called(1);
  });

  test('does not serve a cache entry from another identity scope', () async {
    final request = RequestOptions(path: '/items', method: 'GET');
    final key = CacheInterceptor.cacheKey(request, scope: 'scope-a');
    when(() => monitor.isOnline).thenAnswer((_) async => false);
    when(() => box.get(key)).thenReturn(<String, Object?>{
      'data': 'private',
      'statusCode': 200,
      'scope': 'scope-b',
      'storedAt': DateTime.utc(2026, 1, 1).millisecondsSinceEpoch,
      'version': 1,
    });
    when(() => box.delete(key)).thenAnswer((_) async {});
    final handler = _RequestHandler();

    await interceptor.onRequest(request, handler);

    verify(() => handler.next(request)).called(1);
    verify(() => box.delete(key)).called(1);
  });
}
