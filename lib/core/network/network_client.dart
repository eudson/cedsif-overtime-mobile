import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'package:cedsif_overtime_mobile/core/config/environment_config.dart';
import 'package:cedsif_overtime_mobile/core/network/auth_event_bus.dart';
import 'package:cedsif_overtime_mobile/core/network/cache_interceptor.dart';
import 'package:cedsif_overtime_mobile/core/network/network_monitor.dart';
import 'package:cedsif_overtime_mobile/core/network/token_refresh_interceptor.dart';
import 'package:cedsif_overtime_mobile/core/storage/secure_storage.dart';
import 'package:cedsif_overtime_mobile/core/utils/logger.dart';

void _logNetworkMessage(Object message) {
  final normalizedMessage = message.toString().replaceAll(
    RegExp('%40', caseSensitive: false),
    '@',
  );
  AppLogger.debug(normalizedMessage);
}

class AuthHeaderInterceptor extends Interceptor {
  const AuthHeaderInterceptor(this._secureStorage);

  final SecureStorage _secureStorage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accessToken = await _secureStorage.readAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }
}

class NetworkClient {
  const NetworkClient._(this.dio);

  final Dio dio;

  factory NetworkClient.create({
    required SecureStorage secureStorage,
    required AuthEventBus authEventBus,
    required NetworkMonitor networkMonitor,
    required Box<dynamic> cacheBox,
    String baseUrl = EnvironmentConfig.apiBaseUrl,
    Duration? timeout,
    bool includeDebugLogger = kDebugMode,
  }) {
    final resolvedTimeout = timeout ?? EnvironmentConfig.apiTimeout;
    final options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: resolvedTimeout,
      receiveTimeout: resolvedTimeout,
      sendTimeout: resolvedTimeout,
    );
    final dio = Dio(options);
    final refreshDio = Dio(options);
    dio.interceptors.clear(keepImplyContentTypeInterceptor: false);
    dio.interceptors.addAll(<Interceptor>[
      AuthHeaderInterceptor(secureStorage),
      TokenRefreshInterceptor(
        dio: dio,
        refreshDio: refreshDio,
        secureStorage: secureStorage,
        authEventBus: authEventBus,
      ),
      CacheInterceptor(cacheBox: cacheBox, networkMonitor: networkMonitor),
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
    return NetworkClient._(dio);
  }
}
