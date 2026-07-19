import 'package:workmanager/workmanager.dart';

import 'package:cedsif_overtime_mobile/core/sync/sync_constants.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    return taskName == SyncConstants.taskName ||
        taskName == SyncConstants.uniqueWorkName;
  });
}

class BackgroundSyncWorker {
  BackgroundSyncWorker([Workmanager? workmanager])
    : _workmanager = workmanager ?? Workmanager();

  final Workmanager _workmanager;

  Future<void> initialize() => _workmanager.initialize(callbackDispatcher);

  Future<void> registerPeriodicSync() => _workmanager.registerPeriodicTask(
    SyncConstants.uniqueWorkName,
    SyncConstants.taskName,
    frequency: SyncConstants.frequency,
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
  );
}
