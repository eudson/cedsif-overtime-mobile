import 'package:flutter_test/flutter_test.dart';

import 'package:cedsif_overtime_mobile/core/network/auth_event_bus.dart';

void main() {
  test('broadcasts session expiry to every listener', () async {
    final bus = AuthEventBus();
    final first = expectLater(bus.events, emits(AuthEvent.sessionExpired));
    final second = expectLater(bus.events, emits(AuthEvent.sessionExpired));

    bus.emit(AuthEvent.sessionExpired);

    await Future.wait(<Future<void>>[first, second]);
    await bus.dispose();
  });

  test('closes the event stream when disposed', () async {
    final bus = AuthEventBus();
    final completion = expectLater(bus.events, emitsDone);

    await bus.dispose();

    await completion;
  });
}
