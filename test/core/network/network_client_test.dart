import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cedsif_overtime_mobile/core/network/auth_event_bus.dart';
import 'package:cedsif_overtime_mobile/core/network/cache_interceptor.dart';
import 'package:cedsif_overtime_mobile/core/network/network_client.dart';
import 'package:cedsif_overtime_mobile/core/network/network_monitor.dart';
import 'package:cedsif_overtime_mobile/core/network/token_refresh_interceptor.dart';
import 'package:cedsif_overtime_mobile/core/storage/secure_storage.dart';
import 'package:cedsif_overtime_mobile/core/utils/logger.dart';

class _MockBox extends Mock implements Box<dynamic> {}

class _MockNetworkMonitor extends Mock implements NetworkMonitor {}

class _MockSecureStorage extends Mock implements SecureStorage {}

class _RequestHandler extends Mock implements RequestInterceptorHandler {}

class _RecordingSink implements AppLogSink {
  final List<Object?> messages = <Object?>[];

  @override
  void log(
    Level level,
    Object? message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    messages.add(message);
  }
}

void main() {
  tearDown(AppLogger.resetSink);

  test('auth interceptor injects a stored bearer token', () async {
    final storage = _MockSecureStorage();
    when(storage.readAccessToken).thenAnswer((_) async => 'access-token');
    final interceptor = AuthHeaderInterceptor(
      storage,
      apiBaseUrl: 'https://example.test',
    );
    final options = RequestOptions(path: '/items');
    final handler = _RequestHandler();

    await interceptor.onRequest(options, handler);

    expect(options.headers['Authorization'], 'Bearer access-token');
    verify(() => handler.next(options)).called(1);
  });

  test('auth interceptor leaves headers untouched without a token', () async {
    final storage = _MockSecureStorage();
    when(storage.readAccessToken).thenAnswer((_) async => null);
    final interceptor = AuthHeaderInterceptor(
      storage,
      apiBaseUrl: 'https://example.test',
    );
    final options = RequestOptions(path: '/items');
    final handler = _RequestHandler();

    await interceptor.onRequest(options, handler);

    expect(options.headers, isNot(contains('Authorization')));
    verify(() => handler.next(options)).called(1);
  });

  test('builds the stable production interceptor order', () {
    final client = NetworkClient.create(
      secureStorage: _MockSecureStorage(),
      authEventBus: AuthEventBus(),
      networkMonitor: _MockNetworkMonitor(),
      cacheBox: _MockBox(),
      includeDebugLogger: false,
      baseUrl: 'https://example.test',
      timeout: const Duration(seconds: 5),
    );

    expect(client.dio.options.baseUrl, 'https://example.test');
    expect(client.dio.options.connectTimeout, const Duration(seconds: 5));
    expect(client.dio.interceptors, hasLength(3));
    expect(client.dio.interceptors[0], isA<AuthHeaderInterceptor>());
    expect(client.dio.interceptors[1], isA<TokenRefreshInterceptor>());
    expect(client.dio.interceptors[2], isA<CacheInterceptor>());
  });

  test('auth interceptor never attaches credentials cross-origin', () async {
    final storage = _MockSecureStorage();
    when(storage.readAccessToken).thenAnswer((_) async => 'access-token');
    final interceptor = AuthHeaderInterceptor(
      storage,
      apiBaseUrl: 'https://api.example.test',
    );
    final options = RequestOptions(
      path: 'https://attacker.example/items',
      baseUrl: 'https://api.example.test',
    );
    final handler = _RequestHandler();

    await interceptor.onRequest(options, handler);

    expect(options.headers, isNot(contains('Authorization')));
    verifyNever(storage.readAccessToken);
  });

  test('debug network logs use AppLogger redaction', () {
    final sink = _RecordingSink();
    AppLogger.setSink(sink);
    final client = NetworkClient.create(
      secureStorage: _MockSecureStorage(),
      authEventBus: AuthEventBus(),
      networkMonitor: _MockNetworkMonitor(),
      cacheBox: _MockBox(),
      includeDebugLogger: true,
      baseUrl: 'https://example.test',
      timeout: const Duration(seconds: 5),
    );
    final request = RequestOptions(
      baseUrl: 'https://example.test',
      path: '/items',
      queryParameters: <String, Object?>{
        'email': 'person@example.com',
        'token': 'raw-token-value',
      },
    );

    client.dio.interceptors.last.onRequest(request, _RequestHandler());

    final received = sink.messages.join('\n');
    expect(sink.messages, isNotEmpty);
    expect(received, isNot(contains('person@example.com')));
    expect(received, isNot(contains('person%40example.com')));
    expect(received, isNot(contains('raw-token-value')));
    expect(received, contains('[REDACTED]'));
  });
}
