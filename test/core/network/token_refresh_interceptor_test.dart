import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cedsif_overtime_mobile/core/auth/authenticated_subject.dart';
import 'package:cedsif_overtime_mobile/core/auth/session_mutation_coordinator.dart';
import 'package:cedsif_overtime_mobile/core/constants/api_endpoints.dart';
import 'package:cedsif_overtime_mobile/core/network/auth_event_bus.dart';
import 'package:cedsif_overtime_mobile/core/network/token_refresh_interceptor.dart';
import 'package:cedsif_overtime_mobile/core/storage/secure_storage.dart';

class _MockSecureStorage extends Mock implements SecureStorage {}

class _QueueAdapter implements HttpClientAdapter {
  _QueueAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => handler(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(int status, Map<String, Object?> body) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );

String _jwt(String subject) {
  final payload = base64Url
      .encode(utf8.encode(jsonEncode(<String, String>{'sub': subject})))
      .replaceAll('=', '');
  return 'eyJhbGciOiJub25lIn0.$payload.signature';
}

void main() {
  late _MockSecureStorage storage;
  late AuthEventBus eventBus;

  setUp(() {
    storage = _MockSecureStorage();
    eventBus = AuthEventBus();
    when(storage.clearTokens).thenAnswer((_) async {});
  });

  tearDown(() => eventBus.dispose());

  test('a 401 refreshes tokens and retries the request once', () async {
    var protectedCalls = 0;
    var refreshCalls = 0;
    final requestDio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    final refreshDio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    requestDio.httpClientAdapter = _QueueAdapter((options) async {
      protectedCalls += 1;
      if (protectedCalls == 1) {
        return _jsonResponse(401, <String, Object?>{'error': 'expired'});
      }
      expect(options.headers['Authorization'], 'Bearer fresh-access');
      expect(options.extra[TokenRefreshInterceptor.retryMarker], isTrue);
      return _jsonResponse(200, <String, Object?>{'ok': true});
    });
    refreshDio.httpClientAdapter = _QueueAdapter((options) async {
      refreshCalls += 1;
      expect(options.path, ApiEndpoints.refreshToken);
      return _jsonResponse(200, <String, Object?>{
        'accessToken': 'fresh-access',
        'refreshToken': 'fresh-refresh',
      });
    });
    when(storage.readRefreshToken).thenAnswer((_) async => 'old-refresh');
    when(storage.readAccessToken).thenAnswer((_) async => 'fresh-access');
    when(
      () => storage.writeTokens(
        accessToken: 'fresh-access',
        refreshToken: 'fresh-refresh',
      ),
    ).thenAnswer((_) async {});
    requestDio.interceptors.add(
      TokenRefreshInterceptor(
        dio: requestDio,
        refreshDio: refreshDio,
        secureStorage: storage,
        authEventBus: eventBus,
      ),
    );

    final response = await requestDio.get<dynamic>('/protected');

    expect(response.statusCode, 200);
    expect(protectedCalls, 2);
    expect(refreshCalls, 1);
    verify(
      () => storage.writeTokens(
        accessToken: 'fresh-access',
        refreshToken: 'fresh-refresh',
      ),
    ).called(1);
  });

  test('concurrent 401 responses share one refresh operation', () async {
    var refreshCalls = 0;
    final requestDio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    final refreshDio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    requestDio.httpClientAdapter = _QueueAdapter((options) async {
      if (options.extra[TokenRefreshInterceptor.retryMarker] == true) {
        return _jsonResponse(200, <String, Object?>{'ok': true});
      }
      return _jsonResponse(401, <String, Object?>{'error': 'expired'});
    });
    refreshDio.httpClientAdapter = _QueueAdapter((options) async {
      refreshCalls += 1;
      await Future<void>.delayed(const Duration(milliseconds: 10));
      return _jsonResponse(200, <String, Object?>{
        'accessToken': 'fresh-access',
        'refreshToken': 'fresh-refresh',
      });
    });
    when(storage.readRefreshToken).thenAnswer((_) async => 'old-refresh');
    when(storage.readAccessToken).thenAnswer((_) async => 'fresh-access');
    when(
      () => storage.writeTokens(
        accessToken: any(named: 'accessToken'),
        refreshToken: any(named: 'refreshToken'),
      ),
    ).thenAnswer((_) async {});
    requestDio.interceptors.add(
      TokenRefreshInterceptor(
        dio: requestDio,
        refreshDio: refreshDio,
        secureStorage: storage,
        authEventBus: eventBus,
      ),
    );

    await Future.wait(<Future<Response<dynamic>>>[
      requestDio.get<dynamic>('/first'),
      requestDio.get<dynamic>('/second'),
    ]);

    expect(refreshCalls, 1);
  });

  test(
    'does not retry an owner-bound request with another subject token',
    () async {
      var protectedCalls = 0;
      final requestDio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      final refreshDio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      requestDio.httpClientAdapter = _QueueAdapter((_) async {
        protectedCalls += 1;
        return _jsonResponse(401, <String, Object?>{'error': 'expired'});
      });
      refreshDio.httpClientAdapter = _QueueAdapter((_) async {
        return _jsonResponse(200, <String, Object?>{
          'accessToken': _jwt('employee-2'),
          'refreshToken': 'employee-2-refresh',
        });
      });
      when(storage.readRefreshToken).thenAnswer((_) async => 'refresh-token');
      when(
        () => storage.writeTokens(
          accessToken: any(named: 'accessToken'),
          refreshToken: 'employee-2-refresh',
        ),
      ).thenAnswer((_) async {});
      when(storage.readAccessToken).thenAnswer((_) async => _jwt('employee-2'));
      requestDio.interceptors.add(
        TokenRefreshInterceptor(
          dio: requestDio,
          refreshDio: refreshDio,
          secureStorage: storage,
          authEventBus: eventBus,
        ),
      );

      await expectLater(
        requestDio.get<dynamic>(
          '/protected',
          options: Options(
            headers: <String, Object?>{
              'Authorization': 'Bearer ${_jwt('employee-1')}',
            },
            extra: <String, Object?>{
              AuthenticatedRequestContext.expectedSubjectKey: 'employee-1',
            },
          ),
        ),
        throwsA(isA<DioException>()),
      );

      expect(protectedCalls, 1);
    },
  );

  test('in-flight refresh cannot overwrite a replacement login', () async {
    final refreshStarted = Completer<void>();
    final releaseRefresh = Completer<void>();
    final requestDio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    final refreshDio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    requestDio.httpClientAdapter = _QueueAdapter(
      (_) async => _jsonResponse(401, <String, Object?>{'error': 'expired'}),
    );
    refreshDio.httpClientAdapter = _QueueAdapter((_) async {
      refreshStarted.complete();
      await releaseRefresh.future;
      return _jsonResponse(200, <String, Object?>{
        'accessToken': 'employee-1-access',
        'refreshToken': 'employee-1-replacement',
      });
    });
    var refreshTokenReads = 0;
    when(storage.readRefreshToken).thenAnswer((_) async {
      refreshTokenReads += 1;
      return refreshTokenReads == 1
          ? 'employee-1-refresh'
          : 'employee-2-refresh';
    });
    requestDio.interceptors.add(
      TokenRefreshInterceptor(
        dio: requestDio,
        refreshDio: refreshDio,
        secureStorage: storage,
        authEventBus: eventBus,
      ),
    );

    final request = requestDio.get<dynamic>('/protected');
    await refreshStarted.future;
    releaseRefresh.complete();

    await expectLater(request, throwsA(isA<DioException>()));
    verifyNever(
      () => storage.writeTokens(
        accessToken: any(named: 'accessToken'),
        refreshToken: any(named: 'refreshToken'),
      ),
    );
    verifyNever(storage.clearTokens);
  });

  test(
    'login replacement waits for and supersedes an active refresh',
    () async {
      final coordinator = SessionMutationCoordinator();
      final refreshStarted = Completer<void>();
      final releaseRefresh = Completer<void>();
      var currentAccessToken = 'employee-1-access';
      var currentRefreshToken = 'employee-1-refresh';
      var protectedCalls = 0;
      final requestDio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      final refreshDio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      requestDio.httpClientAdapter = _QueueAdapter((_) async {
        protectedCalls += 1;
        return _jsonResponse(protectedCalls == 1 ? 401 : 200, <String, Object?>{
          'ok': protectedCalls > 1,
        });
      });
      refreshDio.httpClientAdapter = _QueueAdapter((_) async {
        refreshStarted.complete();
        await releaseRefresh.future;
        return _jsonResponse(200, <String, Object?>{
          'accessToken': 'employee-1-refreshed',
          'refreshToken': 'employee-1-replacement',
        });
      });
      when(
        storage.readRefreshToken,
      ).thenAnswer((_) async => currentRefreshToken);
      when(storage.readAccessToken).thenAnswer((_) async => currentAccessToken);
      when(
        () => storage.writeTokens(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
        ),
      ).thenAnswer((invocation) async {
        currentAccessToken = invocation.namedArguments[#accessToken]! as String;
        currentRefreshToken =
            invocation.namedArguments[#refreshToken]! as String;
      });
      requestDio.interceptors.add(
        TokenRefreshInterceptor(
          dio: requestDio,
          refreshDio: refreshDio,
          secureStorage: storage,
          authEventBus: eventBus,
          sessionMutationCoordinator: coordinator,
        ),
      );

      final request = requestDio.get<dynamic>('/protected');
      await refreshStarted.future;
      final replacementLogin = coordinator.run(
        () => storage.writeTokens(
          accessToken: 'employee-2-access',
          refreshToken: 'employee-2-refresh',
        ),
      );
      releaseRefresh.complete();
      await request;
      await replacementLogin;

      expect(currentAccessToken, 'employee-2-access');
      expect(currentRefreshToken, 'employee-2-refresh');
    },
  );

  test('failed refresh clears tokens and emits session expiry', () async {
    final requestDio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    final refreshDio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    requestDio.httpClientAdapter = _QueueAdapter(
      (_) async => _jsonResponse(401, <String, Object?>{'error': 'expired'}),
    );
    refreshDio.httpClientAdapter = _QueueAdapter(
      (_) async => _jsonResponse(401, <String, Object?>{'error': 'invalid'}),
    );
    when(storage.readRefreshToken).thenAnswer((_) async => 'old-refresh');
    requestDio.interceptors.add(
      TokenRefreshInterceptor(
        dio: requestDio,
        refreshDio: refreshDio,
        secureStorage: storage,
        authEventBus: eventBus,
      ),
    );
    final event = expectLater(eventBus.events, emits(AuthEvent.sessionExpired));

    await expectLater(
      requestDio.get<dynamic>('/protected'),
      throwsA(isA<DioException>()),
    );

    await event;
    verify(storage.clearTokens).called(1);
  });

  test('session expiry is emitted when token clearing itself fails', () async {
    final requestDio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    final refreshDio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    requestDio.httpClientAdapter = _QueueAdapter(
      (_) async => _jsonResponse(401, <String, Object?>{'error': 'expired'}),
    );
    when(storage.readRefreshToken).thenAnswer((_) async => null);
    when(storage.clearTokens).thenThrow(StateError('storage unavailable'));
    requestDio.interceptors.add(
      TokenRefreshInterceptor(
        dio: requestDio,
        refreshDio: refreshDio,
        secureStorage: storage,
        authEventBus: eventBus,
      ),
    );
    final event = expectLater(eventBus.events, emits(AuthEvent.sessionExpired));

    await expectLater(
      requestDio.get<dynamic>('/protected'),
      throwsA(isA<DioException>()),
    );

    await event;
  });

  test('failed refresh invokes session cache clearing', () async {
    final requestDio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    final refreshDio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    requestDio.httpClientAdapter = _QueueAdapter(
      (_) async => _jsonResponse(401, <String, Object?>{'error': 'expired'}),
    );
    when(storage.readRefreshToken).thenAnswer((_) async => null);
    var cacheCleared = false;
    requestDio.interceptors.add(
      TokenRefreshInterceptor(
        dio: requestDio,
        refreshDio: refreshDio,
        secureStorage: storage,
        authEventBus: eventBus,
        onSessionExpired: () async => cacheCleared = true,
      ),
    );

    await expectLater(
      requestDio.get<dynamic>('/protected'),
      throwsA(isA<DioException>()),
    );

    expect(cacheCleared, isTrue);
  });

  test('login rejection never attempts token refresh', () async {
    var refreshCalls = 0;
    final requestDio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    final refreshDio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    requestDio.httpClientAdapter = _QueueAdapter(
      (_) async => _jsonResponse(401, <String, Object?>{'error': 'invalid'}),
    );
    refreshDio.httpClientAdapter = _QueueAdapter((_) async {
      refreshCalls += 1;
      return _jsonResponse(500, <String, Object?>{'error': 'unexpected'});
    });
    requestDio.interceptors.add(
      TokenRefreshInterceptor(
        dio: requestDio,
        refreshDio: refreshDio,
        secureStorage: storage,
        authEventBus: eventBus,
      ),
    );

    await expectLater(
      requestDio.post<dynamic>(ApiEndpoints.login),
      throwsA(isA<DioException>()),
    );

    expect(refreshCalls, 0);
    verifyNever(storage.readRefreshToken);
    verifyNever(storage.clearTokens);
  });
}
