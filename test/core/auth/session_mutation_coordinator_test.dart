import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:cedsif_overtime_mobile/core/auth/session_mutation_coordinator.dart';

void main() {
  test('serializes session mutations in request order', () async {
    final coordinator = SessionMutationCoordinator();
    final releaseFirst = Completer<void>();
    final events = <String>[];

    final first = coordinator.run(() async {
      events.add('first-start');
      await releaseFirst.future;
      events.add('first-end');
    });
    final second = coordinator.run(() async {
      events.add('second');
    });
    await Future<void>.delayed(Duration.zero);

    expect(events, <String>['first-start']);
    releaseFirst.complete();
    await Future.wait<void>(<Future<void>>[first, second]);

    expect(events, <String>['first-start', 'first-end', 'second']);
  });
}
