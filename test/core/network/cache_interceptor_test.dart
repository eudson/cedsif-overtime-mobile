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
    interceptor = CacheInterceptor(cacheBox: box, networkMonitor: monitor);
  });

  test('offline GET resolves a cached successful response', () async {
    final request = RequestOptions(
      baseUrl: 'https://example.test',
      path: '/items',
      method: 'GET',
      headers: <String, Object?>{'Authorization': 'Bearer secret'},
    );
    final key = CacheInterceptor.cacheKey(request);
    when(() => monitor.isOnline).thenAnswer((_) async => false);
    when(() => box.get(key)).thenReturn(<String, Object?>{
      'data': <String, Object?>{'ok': true},
      'statusCode': 200,
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

    expect(CacheInterceptor.cacheKey(first), CacheInterceptor.cacheKey(second));
    expect(CacheInterceptor.cacheKey(first), isNot(contains('first')));
  });

  test('ignores malformed offline cache entries', () async {
    final request = RequestOptions(path: '/items', method: 'GET');
    when(() => monitor.isOnline).thenAnswer((_) async => false);
    when(
      () => box.get(CacheInterceptor.cacheKey(request)),
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
    final key = CacheInterceptor.cacheKey(getRequest);
    final cached = <String, Object?>{
      'data': <String, Object?>{'ok': true},
      'statusCode': 200,
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
    final key = CacheInterceptor.cacheKey(request);
    final cached = <String, Object?>{
      'data': <String, Object?>{'ok': true},
      'statusCode': 200,
    };
    when(() => box.put(key, cached)).thenThrow(StateError('cache unavailable'));
    final handler = _ResponseHandler();

    await interceptor.onResponse(response, handler);

    verify(() => handler.next(response)).called(1);
  });
}
