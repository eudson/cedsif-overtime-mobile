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

  void requestSync() {
    if (_syncEngine.isOnline) {
      _process();
    }
  }

  void _process() {
    unawaited(_processPendingRequests());
  }

  Future<void> dispose() => _connectivitySubscription.cancel();
}
