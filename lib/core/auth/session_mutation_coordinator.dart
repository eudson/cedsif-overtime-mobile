import 'dart:async';

class SessionMutationCoordinator {
  SessionMutationCoordinator();

  static final SessionMutationCoordinator shared = SessionMutationCoordinator();

  Future<void> _tail = Future<void>.value();

  Future<T> run<T>(Future<T> Function() operation) {
    final previous = _tail;
    final completion = Completer<void>();
    _tail = completion.future;
    return () async {
      await previous;
      try {
        return await operation();
      } finally {
        completion.complete();
      }
    }();
  }
}
