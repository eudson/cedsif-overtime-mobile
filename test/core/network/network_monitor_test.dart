import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cedsif_overtime_mobile/core/network/network_monitor.dart';

class _MockConnectivity extends Mock implements Connectivity {}

void main() {
  test('reports offline only when no connection is available', () async {
    final connectivity = _MockConnectivity();
    when(
      connectivity.checkConnectivity,
    ).thenAnswer((_) async => <ConnectivityResult>[ConnectivityResult.none]);

    final monitor = NetworkMonitor(connectivity);

    expect(await monitor.isOnline, isFalse);
  });

  test('maps connectivity changes to distinct online states', () async {
    final connectivity = _MockConnectivity();
    when(() => connectivity.onConnectivityChanged).thenAnswer(
      (_) => Stream<List<ConnectivityResult>>.fromIterable(
        <List<ConnectivityResult>>[
          <ConnectivityResult>[ConnectivityResult.wifi],
          <ConnectivityResult>[ConnectivityResult.mobile],
          <ConnectivityResult>[ConnectivityResult.none],
        ],
      ),
    );

    final monitor = NetworkMonitor(connectivity);

    expect(await monitor.changes.toList(), <bool>[true, false]);
  });
}
