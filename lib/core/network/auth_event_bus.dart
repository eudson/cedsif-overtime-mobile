import 'dart:async';

enum AuthEvent { sessionExpired }

class AuthEventBus {
  final StreamController<AuthEvent> _controller =
      StreamController<AuthEvent>.broadcast();
  bool _isDisposed = false;

  Stream<AuthEvent> get events => _controller.stream;

  void emit(AuthEvent event) {
    if (!_isDisposed) {
      _controller.add(event);
    }
  }

  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    await _controller.close();
  }
}
