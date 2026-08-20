import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'package:cedsif_overtime_mobile/core/config/environment_config.dart';
import 'package:cedsif_overtime_mobile/core/constants/api_endpoints.dart';
import 'package:cedsif_overtime_mobile/core/network/auth_event_bus.dart';
import 'package:cedsif_overtime_mobile/core/network/cache_interceptor.dart';
import 'package:cedsif_overtime_mobile/core/network/network_monitor.dart';
import 'package:cedsif_overtime_mobile/core/network/request_origin.dart';
import 'package:cedsif_overtime_mobile/core/network/token_refresh_interceptor.dart';
import 'package:cedsif_overtime_mobile/core/storage/secure_storage.dart';
import 'package:cedsif_overtime_mobile/core/utils/logger.dart';

typedef NetworkDioFactory = Dio Function(BaseOptions options);

void _logNetworkMessage(Object message) {
  final normalizedMessage = message.toString().replaceAll(
    RegExp('%40', caseSensitive: false),
    '@',
  );
  AppLogger.debug(normalizedMessage);
}

class AuthHeaderInterceptor extends Interceptor {
  const AuthHeaderInterceptor(this._secureStorage, {required String apiBaseUrl})
    : _apiBaseUrl = apiBaseUrl;

  final SecureStorage _secureStorage;
  final String _apiBaseUrl;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!RequestOrigin.isAllowed(options, _apiBaseUrl) ||
        _publicAuthPaths.contains(options.path)) {
      handler.next(options);
      return;
    }
    final accessToken = await _secureStorage.readAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  static const Set<String> _publicAuthPaths = <String>{
    ApiEndpoints.login,
    ApiEndpoints.refreshToken,
    ApiEndpoints.logout,
  };
}

class NetworkClient {
  const NetworkClient._(this.dio, this._refreshDio);

  final Dio dio;
  final Dio _refreshDio;

  factory NetworkClient.create({
    required SecureStorage secureStorage,
    required AuthEventBus authEventBus,
    required NetworkMonitor networkMonitor,
    required Box<dynamic> cacheBox,
    String baseUrl = EnvironmentConfig.apiBaseUrl,
    Duration? timeout,
    bool includeDebugLogger = kDebugMode,
    NetworkDioFactory dioFactory = Dio.new,
  }) {
    final resolvedTimeout = timeout ?? EnvironmentConfig.apiTimeout;
    final options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: resolvedTimeout,
      receiveTimeout: resolvedTimeout,
      sendTimeout: resolvedTimeout,
    );
    final dio = dioFactory(options);
    final refreshDio = dioFactory(options);
    dio.interceptors.clear();
    dio.interceptors.addAll(<Interceptor>[
      AuthHeaderInterceptor(secureStorage, apiBaseUrl: baseUrl),
      TokenRefreshInterceptor(
        dio: dio,
        refreshDio: refreshDio,
        secureStorage: secureStorage,
        authEventBus: authEventBus,
        apiBaseUrl: baseUrl,
        onSessionExpired: () => cacheBox.clear().then((_) {}),
      ),
      CacheInterceptor(
        cacheBox: cacheBox,
        networkMonitor: networkMonitor,
        scopeProvider: () async {
          final token = await secureStorage.readAccessToken();
          return token == null || token.isEmpty
              ? 'anonymous'
              : sha256.convert(utf8.encode(token)).toString();
        },
      ),
      if (includeDebugLogger)
        PrettyDioLogger(
          requestHeader: false,
          requestBody: false,
          responseHeader: false,
          responseBody: false,
          error: false,
          compact: true,
          logPrint: _logNetworkMessage,
        ),
    ]);
    return NetworkClient._(dio, refreshDio);
  }

  void close({bool force = false}) {
    dio.close(force: force);
    _refreshDio.close(force: force);
  }
}
