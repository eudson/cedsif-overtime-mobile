import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';

import 'package:cedsif_overtime_mobile/core/constants/constants.dart';
import 'package:cedsif_overtime_mobile/core/network/network_monitor.dart';

typedef CacheScopeProvider = Future<String> Function();
typedef CacheClock = DateTime Function();

class CacheInterceptor extends Interceptor {
  CacheInterceptor({
    required Box<dynamic> cacheBox,
    required NetworkMonitor networkMonitor,
    required CacheScopeProvider scopeProvider,
    CacheClock? now,
    this.ttl = AppConstants.cacheTtl,
  }) : _cacheBox = cacheBox,
       _networkMonitor = networkMonitor,
       _scopeProvider = scopeProvider,
       _now = now ?? DateTime.now;

  final Box<dynamic> _cacheBox;
  final NetworkMonitor _networkMonitor;
  final CacheScopeProvider _scopeProvider;
  final CacheClock _now;
  final Duration ttl;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isGet(options)) {
      handler.next(options);
      return;
    }

    final online = await _networkMonitor.isOnline;
    if (online) {
      handler.next(options);
      return;
    }

    final scope = await _scopeProvider();
    final key = cacheKey(options, scope: scope);
    final cached = _toStringKeyedMap(_cacheBox.get(key));
    if (cached == null) {
      handler.next(options);
      return;
    }

    final storedAt = cached['storedAt'];
    final valid =
        cached['version'] == AppConstants.cacheVersion &&
        cached['scope'] == scope &&
        storedAt is int &&
        !_now().isAfter(DateTime.fromMillisecondsSinceEpoch(storedAt).add(ttl));
    if (!valid) {
      try {
        await _cacheBox.delete(key);
      } on Object {
        // Invalid cache entries are ignored even if cleanup is unavailable.
      }
      handler.next(options);
      return;
    }

    handler.resolve(
      Response<dynamic>(
        requestOptions: options,
        data: cached['data'],
        statusCode: cached['statusCode'] as int?,
      ),
    );
  }

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    final statusCode = response.statusCode;
    if (_isGet(response.requestOptions) &&
        statusCode != null &&
        statusCode >= 200 &&
        statusCode < 300) {
      try {
        final scope = await _scopeProvider();
        await _cacheBox.put(
          cacheKey(response.requestOptions, scope: scope),
          <String, Object?>{
            'data': response.data,
            'statusCode': statusCode,
            'scope': scope,
            'storedAt': _now().millisecondsSinceEpoch,
            'version': AppConstants.cacheVersion,
          },
        );
      } on Object {
        // Caching is best-effort and must not replace a valid network response.
      }
    }
    handler.next(response);
  }

  static String cacheKey(RequestOptions options, {String scope = ''}) {
    final safeHeaders = <String, String>{};
    final headerNames = options.headers.keys.toList()..sort();
    for (final name in headerNames) {
      final normalizedName = name.toLowerCase();
      if (_safeHeaderNames.contains(normalizedName)) {
        safeHeaders[normalizedName] = options.headers[name].toString();
      }
    }
    final source = jsonEncode(<String, Object?>{
      'method': options.method.toUpperCase(),
      'uri': options.uri.toString(),
      'headers': safeHeaders,
      'scope': scope,
    });
    return sha256.convert(utf8.encode(source)).toString();
  }

  static const Set<String> _safeHeaderNames = <String>{
    'accept',
    'accept-language',
    'content-type',
  };

  static bool _isGet(RequestOptions options) =>
      options.method.toUpperCase() == 'GET';

  static Map<String, Object?>? _toStringKeyedMap(Object? value) {
    if (value is! Map<Object?, Object?>) {
      return null;
    }
    final result = <String, Object?>{};
    for (final entry in value.entries) {
      final key = entry.key;
      if (key is! String) {
        return null;
      }
      result[key] = entry.value;
    }
    return result;
  }
}
