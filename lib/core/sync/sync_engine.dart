import 'dart:async';

class SyncEngine {
  SyncEngine({
    required Stream<bool> connectivityChanges,
    required bool initiallyOnline,
  }) : _isOnline = initiallyOnline {
    _connectivitySubscription = connectivityChanges.distinct().listen(
      _handleConnectivityChange,
    );
  }

  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();
  late final StreamSubscription<bool> _connectivitySubscription;
  bool _isOnline;
  bool _isDisposed = false;

  bool get isOnline => _isOnline;

  Stream<bool> get connectivityStates => _connectivityController.stream;

  void _handleConnectivityChange(bool isOnline) {
    if (_isDisposed || isOnline == _isOnline) {
      return;
    }
    _isOnline = isOnline;
    _connectivityController.add(isOnline);
  }

  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    await _connectivitySubscription.cancel();
    await _connectivityController.close();
  }
}
