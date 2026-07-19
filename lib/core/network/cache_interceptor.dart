import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';

import 'package:cedsif_overtime_mobile/core/network/network_monitor.dart';

class CacheInterceptor extends Interceptor {
  const CacheInterceptor({
    required Box<dynamic> cacheBox,
    required NetworkMonitor networkMonitor,
  }) : _cacheBox = cacheBox,
       _networkMonitor = networkMonitor;

  final Box<dynamic> _cacheBox;
  final NetworkMonitor _networkMonitor;

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

    final cached = _toStringKeyedMap(_cacheBox.get(cacheKey(options)));
    if (cached == null) {
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
        await _cacheBox.put(
          cacheKey(response.requestOptions),
          <String, Object?>{'data': response.data, 'statusCode': statusCode},
        );
      } on Object {
        // Caching is best-effort and must not replace a valid network response.
      }
    }
    handler.next(response);
  }

  static String cacheKey(RequestOptions options) {
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
