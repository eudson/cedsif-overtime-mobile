import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:cedsif_overtime_mobile/core/sync/sync_engine.dart';

void main() {
  test('starts with the injected connectivity state', () {
    final controller = StreamController<bool>();
    final engine = SyncEngine(
      connectivityChanges: controller.stream,
      initiallyOnline: false,
    );
    addTearDown(() async {
      await engine.dispose();
      await controller.close();
    });

    expect(engine.isOnline, isFalse);
  });

  test('emits only distinct connectivity states', () async {
    final controller = StreamController<bool>();
    final engine = SyncEngine(
      connectivityChanges: controller.stream,
      initiallyOnline: false,
    );
    addTearDown(() async {
      await engine.dispose();
      await controller.close();
    });
    final emitted = <bool>[];
    final subscription = engine.connectivityStates.listen(emitted.add);
    addTearDown(subscription.cancel);

    controller
      ..add(false)
      ..add(true)
      ..add(true)
      ..add(false);
    await pumpEventQueue();

    expect(emitted, <bool>[true, false]);
    expect(engine.isOnline, isFalse);
  });

  test('stops observing connectivity after disposal', () async {
    final controller = StreamController<bool>();
    final engine = SyncEngine(
      connectivityChanges: controller.stream,
      initiallyOnline: false,
    );
    final emitted = <bool>[];
    engine.connectivityStates.listen(emitted.add);

    await engine.dispose();
    controller.add(true);
    await pumpEventQueue();
    await controller.close();

    expect(emitted, isEmpty);
  });
}
