import 'package:workmanager/workmanager.dart';

import 'package:cedsif_overtime_mobile/core/database/app_database.dart';
import 'package:cedsif_overtime_mobile/core/network/auth_event_bus.dart';
import 'package:cedsif_overtime_mobile/core/network/network_client.dart';
import 'package:cedsif_overtime_mobile/core/network/network_monitor.dart';
import 'package:cedsif_overtime_mobile/core/storage/secure_storage.dart';
import 'package:cedsif_overtime_mobile/core/sync/generic_sync_processor.dart';
import 'package:cedsif_overtime_mobile/core/sync/sync_constants.dart';

typedef GenericSyncOperation = Future<bool> Function();

Future<bool> executeBackgroundTask(
  String taskName,
  GenericSyncOperation syncOperation,
) async {
  if (taskName != SyncConstants.taskName &&
      taskName != SyncConstants.uniqueWorkName) {
    return false;
  }

  try {
    return await syncOperation();
  } on Object {
    return false;
  }
}

Future<bool> processGenericBackgroundQueue() async {
  final database = await AppDatabase.initialize();
  final authEventBus = AuthEventBus();
  NetworkClient? networkClient;
  try {
    networkClient = NetworkClient.create(
      secureStorage: const SecureStorage(),
      authEventBus: authEventBus,
      networkMonitor: NetworkMonitor(),
      cacheBox: database.cacheBox,
    );
    return GenericSyncProcessor(
      pendingRequestsBox: database.pendingRequestsBox,
      handler: DioPendingRequestHandler(networkClient.dio),
    ).processPendingRequests();
  } finally {
    networkClient?.dio.close(force: true);
    await authEventBus.dispose();
    await Future.wait(<Future<void>>[
      database.cacheBox.close(),
      database.pendingRequestsBox.close(),
    ]);
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    return executeBackgroundTask(taskName, processGenericBackgroundQueue);
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
