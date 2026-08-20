import 'dart:async';

import 'package:dio/dio.dart';

import 'package:cedsif_overtime_mobile/core/constants/api_endpoints.dart';
import 'package:cedsif_overtime_mobile/core/network/auth_event_bus.dart';
import 'package:cedsif_overtime_mobile/core/network/request_origin.dart';
import 'package:cedsif_overtime_mobile/core/storage/secure_storage.dart';

class TokenRefreshInterceptor extends Interceptor {
  TokenRefreshInterceptor({
    required Dio dio,
    required Dio refreshDio,
    required SecureStorage secureStorage,
    required AuthEventBus authEventBus,
    String? apiBaseUrl,
    Future<void> Function()? onSessionExpired,
  }) : _dio = dio,
       _refreshDio = refreshDio,
       _secureStorage = secureStorage,
       _authEventBus = authEventBus,
       _apiBaseUrl = apiBaseUrl ?? dio.options.baseUrl,
       _onSessionExpired = onSessionExpired;

  static const String retryMarker = 'auth_refresh_retried';

  final Dio _dio;
  final Dio _refreshDio;
  final SecureStorage _secureStorage;
  final AuthEventBus _authEventBus;
  final String _apiBaseUrl;
  final Future<void> Function()? _onSessionExpired;
  Future<bool>? _activeRefresh;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    if (err.response?.statusCode != 401 ||
        !RequestOrigin.isAllowed(request, _apiBaseUrl) ||
        request.extra[retryMarker] == true ||
        _publicAuthPaths.contains(request.path)) {
      handler.next(err);
      return;
    }

    final refreshed = await _refreshOnce();
    if (!refreshed) {
      handler.next(err);
      return;
    }

    try {
      final accessToken = await _secureStorage.readAccessToken();
      final retryOptions = request.copyWith(
        headers: <String, dynamic>{
          ...request.headers,
          if (accessToken != null && accessToken.isNotEmpty)
            'Authorization': 'Bearer $accessToken',
        },
        extra: <String, dynamic>{...request.extra, retryMarker: true},
      );
      handler.resolve(await _dio.fetch<dynamic>(retryOptions));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  static const Set<String> _publicAuthPaths = <String>{
    ApiEndpoints.login,
    ApiEndpoints.refreshToken,
    ApiEndpoints.logout,
  };

  Future<bool> _refreshOnce() {
    final active = _activeRefresh;
    if (active != null) {
      return active;
    }

    final operation = _refreshTokens();
    _activeRefresh = operation;
    operation.whenComplete(() {
      if (identical(_activeRefresh, operation)) {
        _activeRefresh = null;
      }
    });
    return operation;
  }

  Future<bool> _refreshTokens() async {
    try {
      final refreshToken = await _secureStorage.readRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return _expireSession();
      }
      final response = await _refreshDio.post<dynamic>(
        ApiEndpoints.refreshToken,
        data: <String, Object?>{'refreshToken': refreshToken},
      );
      final data = response.data;
      if (data is! Map<Object?, Object?>) {
        return _expireSession();
      }
      final accessToken = data['accessToken'];
      final replacementRefreshToken = data['refreshToken'];
      if (accessToken is! String ||
          accessToken.isEmpty ||
          replacementRefreshToken is! String ||
          replacementRefreshToken.isEmpty) {
        return _expireSession();
      }
      await _secureStorage.writeTokens(
        accessToken: accessToken,
        refreshToken: replacementRefreshToken,
      );
      return true;
    } on Object {
      return _expireSession();
    }
  }

  Future<bool> _expireSession() async {
    try {
      await _secureStorage.clearTokens();
    } on Object {
      // Session expiry still propagates when the platform store is unavailable.
    } finally {
      try {
        await _onSessionExpired?.call();
      } on Object {
        // Session expiry still propagates when cache cleanup is unavailable.
      }
      _authEventBus.emit(AuthEvent.sessionExpired);
    }
    return false;
  }
}
