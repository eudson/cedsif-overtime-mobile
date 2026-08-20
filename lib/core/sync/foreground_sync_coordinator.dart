import 'dart:async';

import 'package:cedsif_overtime_mobile/core/sync/sync_engine.dart';

typedef PendingRequestProcessor = Future<bool> Function();

class ForegroundSyncCoordinator {
  ForegroundSyncCoordinator({
    required SyncEngine syncEngine,
    required PendingRequestProcessor processPendingRequests,
  }) : _syncEngine = syncEngine,
       _processPendingRequests = processPendingRequests {
    _connectivitySubscription = _syncEngine.connectivityStates.listen((online) {
      if (online) {
        _process();
      }
    });
    requestSync();
  }

  final SyncEngine _syncEngine;
  final PendingRequestProcessor _processPendingRequests;
  late final StreamSubscription<bool> _connectivitySubscription;
  Future<void>? _activeProcessing;
  var _rerunRequested = false;
  var _disposed = false;

  void requestSync() {
    if (_syncEngine.isOnline) {
      _process();
    }
  }

  void _process() {
    _rerunRequested = true;
    if (_activeProcessing != null) {
      return;
    }
    final operation = _drainRequestedPasses();
    _activeProcessing = operation;
    unawaited(
      operation.whenComplete(() {
        if (identical(_activeProcessing, operation)) {
          _activeProcessing = null;
        }
        if (_rerunRequested && !_disposed && _syncEngine.isOnline) {
          _process();
        }
      }),
    );
  }

  Future<void> _drainRequestedPasses() async {
    do {
      _rerunRequested = false;
      await _processPendingRequests();
    } while (_rerunRequested && !_disposed && _syncEngine.isOnline);
  }

  Future<void> dispose() async {
    _disposed = true;
    await _connectivitySubscription.cancel();
    await _activeProcessing;
  }
}
