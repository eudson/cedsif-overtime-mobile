import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cedsif_overtime_mobile/core/auth/authenticated_subject.dart';
import 'package:cedsif_overtime_mobile/core/constants/api_endpoints.dart';
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

class _DioExceptionFake extends Fake implements DioException {}

class _RecordingAdapter implements HttpClientAdapter {
  bool isClosed = false;
  bool? force;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => throw UnsupportedError('No requests expected');

  @override
  void close({bool force = false}) {
    isClosed = true;
    this.force = force;
  }
}

class _CapturingAdapter implements HttpClientAdapter {
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      '{"accessToken":"access","refreshToken":"refresh","expiresIn":120}',
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

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

String _jwt(String subject) {
  final payload = base64Url
      .encode(utf8.encode(jsonEncode(<String, String>{'sub': subject})))
      .replaceAll('=', '');
  return 'eyJhbGciOiJub25lIn0.$payload.signature';
}

void main() {
  setUpAll(() => registerFallbackValue(_DioExceptionFake()));
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

  test(
    'auth interceptor preserves an owner-bound bearer token atomically',
    () async {
      final storage = _MockSecureStorage();
      final interceptor = AuthHeaderInterceptor(
        storage,
        apiBaseUrl: 'https://example.test',
      );
      final token = _jwt('employee-1');
      final options = RequestOptions(
        path: '/items',
        headers: <String, Object?>{'Authorization': 'Bearer $token'},
        extra: <String, Object?>{
          AuthenticatedRequestContext.expectedSubjectKey: 'employee-1',
        },
      );
      final handler = _RequestHandler();

      await interceptor.onRequest(options, handler);

      expect(options.headers['Authorization'], 'Bearer $token');
      verifyNever(storage.readAccessToken);
      verify(() => handler.next(options)).called(1);
    },
  );

  test(
    'auth interceptor rejects a bearer token for a changed subject',
    () async {
      final storage = _MockSecureStorage();
      final interceptor = AuthHeaderInterceptor(
        storage,
        apiBaseUrl: 'https://example.test',
      );
      final options = RequestOptions(
        path: '/items',
        headers: <String, Object?>{
          'Authorization': 'Bearer ${_jwt('employee-2')}',
        },
        extra: <String, Object?>{
          AuthenticatedRequestContext.expectedSubjectKey: 'employee-1',
        },
      );
      final handler = _RequestHandler();

      await interceptor.onRequest(options, handler);

      verifyNever(storage.readAccessToken);
      verify(() => handler.reject(any())).called(1);
      verifyNever(() => handler.next(options));
    },
  );

  test(
    'auth interceptor never attaches credentials to auth endpoints',
    () async {
      final storage = _MockSecureStorage();
      when(storage.readAccessToken).thenAnswer((_) async => 'stale-token');
      final interceptor = AuthHeaderInterceptor(
        storage,
        apiBaseUrl: 'https://example.test',
      );
      final handler = _RequestHandler();

      for (final path in <String>[
        ApiEndpoints.login,
        ApiEndpoints.refreshToken,
        ApiEndpoints.logout,
      ]) {
        final options = RequestOptions(path: path);

        await interceptor.onRequest(options, handler);

        expect(options.headers, isNot(contains('Authorization')));
      }
      verifyNever(storage.readAccessToken);
    },
  );

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
    expect(client.dio.interceptors, hasLength(4));
    expect(client.dio.interceptors[1], isA<AuthHeaderInterceptor>());
    expect(client.dio.interceptors[2], isA<TokenRefreshInterceptor>());
    expect(client.dio.interceptors[3], isA<CacheInterceptor>());
  });

  test('background clients can avoid cross-isolate token mutation', () {
    final client = NetworkClient.create(
      secureStorage: _MockSecureStorage(),
      authEventBus: AuthEventBus(),
      networkMonitor: _MockNetworkMonitor(),
      cacheBox: _MockBox(),
      includeDebugLogger: false,
      enableTokenRefresh: false,
    );

    expect(
      client.dio.interceptors,
      isNot(contains(isA<TokenRefreshInterceptor>())),
    );
  });

  test('infers JSON content type for map request bodies', () async {
    final adapters = <_CapturingAdapter>[];
    Dio createDio(BaseOptions options) {
      final adapter = _CapturingAdapter();
      adapters.add(adapter);
      return Dio(options)..httpClientAdapter = adapter;
    }

    final client = NetworkClient.create(
      secureStorage: _MockSecureStorage(),
      authEventBus: AuthEventBus(),
      networkMonitor: _MockNetworkMonitor(),
      cacheBox: _MockBox(),
      includeDebugLogger: false,
      baseUrl: 'https://example.test',
      dioFactory: createDio,
    );

    await client.dio.post<dynamic>(
      ApiEndpoints.login,
      data: <String, Object?>{
        'nuit': '123456789',
        'password': 'local-password',
      },
    );

    expect(adapters.first.request?.contentType, Headers.jsonContentType);
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

  test(
    'auth rejects relative path resolved by a cross-origin base URL',
    () async {
      final storage = _MockSecureStorage();
      when(storage.readAccessToken).thenAnswer((_) async => 'access-token');
      final interceptor = AuthHeaderInterceptor(
        storage,
        apiBaseUrl: 'https://api.example.test',
      );
      final options = RequestOptions(
        path: '/items',
        baseUrl: 'https://attacker.example',
      );
      final handler = _RequestHandler();

      await interceptor.onRequest(options, handler);

      expect(options.headers, isNot(contains('Authorization')));
      verifyNever(storage.readAccessToken);
    },
  );

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

  test('close owns and closes primary and refresh transports', () {
    final adapters = <_RecordingAdapter>[];
    Dio createDio(BaseOptions options) {
      final adapter = _RecordingAdapter();
      adapters.add(adapter);
      return Dio(options)..httpClientAdapter = adapter;
    }

    final client = NetworkClient.create(
      secureStorage: _MockSecureStorage(),
      authEventBus: AuthEventBus(),
      networkMonitor: _MockNetworkMonitor(),
      cacheBox: _MockBox(),
      includeDebugLogger: false,
      baseUrl: 'https://example.test',
      timeout: const Duration(seconds: 5),
      dioFactory: createDio,
    );

    client.close(force: true);

    expect(adapters, hasLength(2));
    expect(adapters.every((adapter) => adapter.isClosed), isTrue);
    expect(adapters.every((adapter) => adapter.force == true), isTrue);
  });
}
