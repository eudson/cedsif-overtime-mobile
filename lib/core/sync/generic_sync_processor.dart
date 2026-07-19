import 'package:hive/hive.dart';

abstract interface class PendingRequestHandler {
  Future<bool> process(Map<String, Object?> request);
}

class GenericSyncProcessor {
  const GenericSyncProcessor({
    required Box<dynamic> pendingRequestsBox,
    required PendingRequestHandler handler,
  }) : _pendingRequestsBox = pendingRequestsBox,
       _handler = handler;

  final Box<dynamic> _pendingRequestsBox;
  final PendingRequestHandler _handler;

  Future<bool> processPendingRequests() async {
    var allSucceeded = true;
    final requests = _pendingRequestsBox.toMap();

    for (final entry in requests.entries) {
      final request = _toStringKeyedMap(entry.value);
      if (request == null) {
        allSucceeded = false;
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

class DeferredPendingRequestHandler implements PendingRequestHandler {
  const DeferredPendingRequestHandler();

  @override
  Future<bool> process(Map<String, Object?> request) async => false;
}
