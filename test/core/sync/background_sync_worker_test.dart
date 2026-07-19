import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:workmanager/workmanager.dart';

import 'package:cedsif_overtime_mobile/core/sync/background_sync_worker.dart';
import 'package:cedsif_overtime_mobile/core/sync/sync_constants.dart';

class _MockWorkmanager extends Mock implements Workmanager {}

void main() {
  late _MockWorkmanager workmanager;
  late BackgroundSyncWorker worker;

  setUpAll(() {
    registerFallbackValue(Constraints());
    registerFallbackValue(ExistingPeriodicWorkPolicy.update);
  });

  setUp(() {
    workmanager = _MockWorkmanager();
    worker = BackgroundSyncWorker(workmanager);
    when(() => workmanager.initialize(any())).thenAnswer((_) async {});
    when(
      () => workmanager.registerPeriodicTask(
        any(),
        any(),
        frequency: any(named: 'frequency'),
        constraints: any(named: 'constraints'),
        existingWorkPolicy: any(named: 'existingWorkPolicy'),
      ),
    ).thenAnswer((_) async {});
  });

  test('initializes the top-level callback dispatcher', () async {
    await worker.initialize();

    verify(() => workmanager.initialize(callbackDispatcher)).called(1);
  });

  test('registers generic periodic sync with a network constraint', () async {
    await worker.registerPeriodicSync();

    final captured =
        verify(
              () => workmanager.registerPeriodicTask(
                SyncConstants.uniqueWorkName,
                SyncConstants.taskName,
                frequency: SyncConstants.frequency,
                constraints: captureAny(named: 'constraints'),
                existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
              ),
            ).captured.single
            as Constraints;
    expect(captured.networkType, NetworkType.connected);
  });
}
