import 'package:dio/dio.dart';
import 'package:hive/hive.dart';

import 'package:cedsif_overtime_mobile/core/auth/authenticated_subject.dart';
import 'package:cedsif_overtime_mobile/core/network/request_origin.dart';

abstract interface class PendingRequestHandler {
  Future<PendingRequestOutcome> process(Map<String, Object?> request);
}

typedef PendingRequestOwnerSubjectProvider = Future<String?> Function();
typedef AuthenticatedTokenProvider = Future<AuthenticatedToken?> Function();

enum PendingRequestOutcome { success, retry, deferred, permanentRejection }

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
    final requests = _pendingRequestsBox.toMap().entries.indexed.toList()
      ..sort((left, right) {
        final leftCreatedAt = _createdAt(left.$2.value, left.$1);
        final rightCreatedAt = _createdAt(right.$2.value, right.$1);
        final timestampOrder = leftCreatedAt.compareTo(rightCreatedAt);
        return timestampOrder != 0
            ? timestampOrder
            : left.$1.compareTo(right.$1);
      });

    for (final indexedEntry in requests) {
      final entry = indexedEntry.$2;
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
        final outcome = await _handler.process(request);
        switch (outcome) {
          case PendingRequestOutcome.success:
            await _pendingRequestsBox.delete(entry.key);
          case PendingRequestOutcome.retry:
            allSucceeded = false;
            await _markForRetry(entry.key, request);
            return false;
          case PendingRequestOutcome.deferred:
            allSucceeded = false;
          case PendingRequestOutcome.permanentRejection:
            allSucceeded = false;
            await _pendingRequestsBox.delete(entry.key);
        }
      } on Object {
        allSucceeded = false;
        await _markForRetry(entry.key, request);
        return false;
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
          (entry.value as String).trim().isNotEmpty) {
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

  DateTime _createdAt(Object? value, int fallbackOrder) {
    final request = _toStringKeyedMap(value);
    final createdAt = request?['createdAt'];
    if (createdAt is String) {
      final parsed = DateTime.tryParse(createdAt);
      if (parsed != null) {
        return parsed.toUtc();
      }
    }
    return DateTime.fromMillisecondsSinceEpoch(fallbackOrder, isUtc: true);
  }
}

class DioPendingRequestHandler implements PendingRequestHandler {
  const DioPendingRequestHandler(
    this._dio, {
    required AuthenticatedTokenProvider authenticatedTokenProvider,
  }) : _authenticatedTokenProvider = authenticatedTokenProvider;

  final Dio _dio;
  final AuthenticatedTokenProvider _authenticatedTokenProvider;

  static const Set<String> _safeHeaderNames = <String>{
    'accept',
    'accept-language',
    'content-type',
    'idempotency-key',
  };

  @override
  Future<PendingRequestOutcome> process(Map<String, Object?> request) async {
    final authenticatedToken = await _authenticatedTokenProvider();
    final requestOwner = request['ownerSubject'];
    if (requestOwner is! String ||
        requestOwner.isEmpty ||
        authenticatedToken == null ||
        authenticatedToken.subject != requestOwner) {
      return PendingRequestOutcome.deferred;
    }
    final method = request['method'];
    final path = request['path'];
    if (method is! String ||
        method.isEmpty ||
        path is! String ||
        path.isEmpty) {
      return PendingRequestOutcome.permanentRejection;
    }

    final headers = <String, Object?>{
      ..._safeHeaders(request['headers']),
      'Authorization': 'Bearer ${authenticatedToken.accessToken}',
    };
    final normalizedMethod = method.toUpperCase();
    if (!RequestOrigin.isAllowedPath(path, _dio.options.baseUrl) ||
        (!_safeMethods.contains(normalizedMethod) &&
            !_hasIdempotencyKey(headers))) {
      return PendingRequestOutcome.permanentRejection;
    }
    try {
      final response = await _dio.request<dynamic>(
        path,
        data: request['body'],
        options: Options(
          method: normalizedMethod,
          headers: headers,
          extra: <String, Object?>{
            AuthenticatedRequestContext.expectedSubjectKey: requestOwner,
          },
        ),
      );
      final statusCode = response.statusCode;
      return statusCode != null && statusCode >= 200 && statusCode < 300
          ? PendingRequestOutcome.success
          : PendingRequestOutcome.retry;
    } on DioException {
      return PendingRequestOutcome.retry;
    }
  }

  static const Set<String> _safeMethods = <String>{'GET', 'HEAD'};

  bool _hasIdempotencyKey(Map<String, Object?> headers) => headers.entries.any(
    (entry) =>
        entry.key.toLowerCase() == 'idempotency-key' &&
        entry.value is String &&
        (entry.value as String).trim().isNotEmpty,
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
