import 'package:dio/dio.dart';
import 'package:hive/hive.dart';

import 'package:cedsif_overtime_mobile/core/network/request_origin.dart';

abstract interface class PendingRequestHandler {
  Future<bool> process(Map<String, Object?> request);
}

class GenericSyncProcessor {
  GenericSyncProcessor({
    required Box<dynamic> pendingRequestsBox,
    required PendingRequestHandler handler,
  }) : _pendingRequestsBox = pendingRequestsBox,
       _handler = handler;

  final Box<dynamic> _pendingRequestsBox;
  final PendingRequestHandler _handler;
  Future<bool>? _activeProcessing;

  Future<bool> processPendingRequests() {
    final active = _activeProcessing;
    if (active != null) {
      return active;
    }
    final operation = _processPendingRequests();
    _activeProcessing = operation;
    operation.whenComplete(() {
      if (identical(_activeProcessing, operation)) {
        _activeProcessing = null;
      }
    });
    return operation;
  }

  Future<bool> _processPendingRequests() async {
    var allSucceeded = true;
    final requests = _pendingRequestsBox.toMap();

    for (final entry in requests.entries) {
      final request = _toStringKeyedMap(entry.value);
      if (request == null || _isPermanentlyInvalid(request)) {
        allSucceeded = false;
        try {
          await _pendingRequestsBox.delete(entry.key);
        } on Object {
          // A later pass may retry quarantine cleanup without sending it.
        }
        continue;
      }

      try {
        final succeeded = await _handler.process(request);
        if (succeeded) {
          await _pendingRequestsBox.delete(entry.key);
        } else {
          allSucceeded = false;
          await _markForRetry(entry.key, request);
        }
      } on Object {
        allSucceeded = false;
        await _markForRetry(entry.key, request);
      }
    }

    return allSucceeded;
  }

  bool _isPermanentlyInvalid(Map<String, Object?> request) {
    final method = request['method'];
    final path = request['path'];
    if (method is! String ||
        method.isEmpty ||
        path is! String ||
        path.isEmpty) {
      return true;
    }
    final normalizedMethod = method.toUpperCase();
    if (normalizedMethod == 'GET' || normalizedMethod == 'HEAD') {
      return false;
    }
    return !_hasIdempotencyKey(request['headers']);
  }

  bool _hasIdempotencyKey(Object? rawHeaders) {
    if (rawHeaders is! Map<Object?, Object?>) {
      return false;
    }
    for (final entry in rawHeaders.entries) {
      if (entry.key is String &&
          (entry.key as String).toLowerCase() == 'idempotency-key' &&
          entry.value is String &&
          (entry.value as String).isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  Future<void> _markForRetry(Object? key, Map<String, Object?> request) async {
    final retryCount = request['retryCount'];
    final updatedRequest = <String, Object?>{
      ...request,
      'retryCount': retryCount is int ? retryCount + 1 : 1,
    };
    try {
      await _pendingRequestsBox.put(key, updatedRequest);
    } on Object {
      // The request remains in the queue when its retry metadata cannot update.
    }
  }

  Map<String, Object?>? _toStringKeyedMap(Object? value) {
    if (value is! Map<Object?, Object?>) {
      return null;
    }

    final request = <String, Object?>{};
    for (final entry in value.entries) {
      final key = entry.key;
      if (key is! String) {
        return null;
      }
      request[key] = entry.value;
    }
    return request;
  }
}

class DioPendingRequestHandler implements PendingRequestHandler {
  const DioPendingRequestHandler(this._dio);

  final Dio _dio;

  static const Set<String> _safeHeaderNames = <String>{
    'accept',
    'accept-language',
    'content-type',
    'idempotency-key',
  };

  @override
  Future<bool> process(Map<String, Object?> request) async {
    final method = request['method'];
    final path = request['path'];
    if (method is! String ||
        method.isEmpty ||
        path is! String ||
        path.isEmpty) {
      return false;
    }

    final headers = _safeHeaders(request['headers']);
    final normalizedMethod = method.toUpperCase();
    if (!RequestOrigin.isAllowedPath(path, _dio.options.baseUrl) ||
        (!_safeMethods.contains(normalizedMethod) &&
            !_hasIdempotencyKey(headers))) {
      return false;
    }
    try {
      final response = await _dio.request<dynamic>(
        path,
        data: request['body'],
        options: Options(method: normalizedMethod, headers: headers),
      );
      final statusCode = response.statusCode;
      return statusCode != null && statusCode >= 200 && statusCode < 300;
    } on DioException {
      return false;
    }
  }

  static const Set<String> _safeMethods = <String>{'GET', 'HEAD'};

  bool _hasIdempotencyKey(Map<String, Object?> headers) => headers.entries.any(
    (entry) =>
        entry.key.toLowerCase() == 'idempotency-key' &&
        entry.value is String &&
        (entry.value as String).isNotEmpty,
  );

  Map<String, Object?> _safeHeaders(Object? rawHeaders) {
    if (rawHeaders is! Map<Object?, Object?>) {
      return const <String, Object?>{};
    }
    final headers = <String, Object?>{};
    for (final entry in rawHeaders.entries) {
      final key = entry.key;
      if (key is String && _safeHeaderNames.contains(key.toLowerCase())) {
        headers[key] = entry.value;
      }
    }
    return headers;
  }
}
