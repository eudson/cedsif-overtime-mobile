import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:workmanager/workmanager.dart';

import 'package:cedsif_overtime_mobile/core/sync/background_sync_worker.dart';
import 'package:cedsif_overtime_mobile/core/sync/sync_constants.dart';

class _MockWorkmanager extends Mock implements Workmanager {}

class _MockGenericSyncOperation extends Mock {
  Future<bool> call();
}

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

  test('background task delegates known work to the sync operation', () async {
    final operation = _MockGenericSyncOperation();
    when(operation.call).thenAnswer((_) async => true);

    final result = await executeBackgroundTask(
      SyncConstants.taskName,
      operation.call,
    );

    expect(result, isTrue);
    verify(operation.call).called(1);
  });

  test('background task safely reports sync operation failure', () async {
    final operation = _MockGenericSyncOperation();
    when(operation.call).thenThrow(StateError('queue unavailable'));

    final result = await executeBackgroundTask(
      SyncConstants.taskName,
      operation.call,
    );

    expect(result, isFalse);
  });

  test('background task rejects unknown work without processing', () async {
    final operation = _MockGenericSyncOperation();

    final result = await executeBackgroundTask('unknown', operation.call);

    expect(result, isFalse);
    verifyNever(operation.call);
  });
}
