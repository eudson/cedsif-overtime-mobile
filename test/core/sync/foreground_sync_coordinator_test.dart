import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:cedsif_overtime_mobile/core/sync/foreground_sync_coordinator.dart';
import 'package:cedsif_overtime_mobile/core/sync/sync_engine.dart';

void main() {
  test('processes at startup and whenever connectivity returns', () async {
    final connectivity = StreamController<bool>();
    final engine = SyncEngine(
      connectivityChanges: connectivity.stream,
      initiallyOnline: true,
    );
    var calls = 0;
    final coordinator = ForegroundSyncCoordinator(
      syncEngine: engine,
      processPendingRequests: () async {
        calls += 1;
        return true;
      },
    );
    addTearDown(() async {
      await coordinator.dispose();
      await engine.dispose();
      await connectivity.close();
    });

    await pumpEventQueue();
    connectivity
      ..add(false)
      ..add(true);
    await pumpEventQueue();

    expect(calls, 2);
  });

  test('requestSync processes only while online', () async {
    final connectivity = StreamController<bool>();
    final engine = SyncEngine(
      connectivityChanges: connectivity.stream,
      initiallyOnline: false,
    );
    var calls = 0;
    final coordinator = ForegroundSyncCoordinator(
      syncEngine: engine,
      processPendingRequests: () async {
        calls += 1;
        return true;
      },
    );
    addTearDown(() async {
      await coordinator.dispose();
      await engine.dispose();
      await connectivity.close();
    });

    coordinator.requestSync();
    await pumpEventQueue();
    expect(calls, 0);

    connectivity.add(true);
    await pumpEventQueue();
    coordinator.requestSync();
    await pumpEventQueue();
    expect(calls, 2);
  });

  test('runs a requested follow-up pass after an active pass', () async {
    final connectivity = StreamController<bool>();
    final engine = SyncEngine(
      connectivityChanges: connectivity.stream,
      initiallyOnline: true,
    );
    final firstPass = Completer<bool>();
    var calls = 0;
    final coordinator = ForegroundSyncCoordinator(
      syncEngine: engine,
      processPendingRequests: () {
        calls += 1;
        return calls == 1 ? firstPass.future : Future<bool>.value(true);
      },
    );
    addTearDown(() async {
      await coordinator.dispose();
      await engine.dispose();
      await connectivity.close();
    });

    await pumpEventQueue();
    coordinator.requestSync();
    await pumpEventQueue();
    expect(calls, 1);
    firstPass.complete(false);
    await pumpEventQueue();

    expect(calls, 2);
  });
}
