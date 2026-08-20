import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cedsif_overtime_mobile/core/database/app_database.dart';
import 'package:cedsif_overtime_mobile/core/auth/authenticated_subject.dart';
import 'package:cedsif_overtime_mobile/core/network/auth_event_bus.dart';
import 'package:cedsif_overtime_mobile/core/network/network_client.dart';
import 'package:cedsif_overtime_mobile/core/network/network_monitor.dart';
import 'package:cedsif_overtime_mobile/core/storage/image_cache_manager.dart';
import 'package:cedsif_overtime_mobile/core/storage/local_storage.dart';
import 'package:cedsif_overtime_mobile/core/storage/secure_storage.dart';
import 'package:cedsif_overtime_mobile/core/sync/sync_engine.dart';
import 'package:cedsif_overtime_mobile/core/sync/foreground_sync_coordinator.dart';
import 'package:cedsif_overtime_mobile/core/sync/generic_sync_processor.dart';
import 'package:cedsif_overtime_mobile/core/utils/logger.dart';

Never _missingBootstrapResource(String name) =>
    throw UnimplementedError('$name must be overridden during bootstrap');

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => _missingBootstrapResource('SharedPreferences'),
);

final localStorageProvider = Provider<LocalStorage>(
  (ref) => LocalStorage(ref.watch(sharedPreferencesProvider)),
);

final secureStorageProvider = Provider<SecureStorage>(
  (ref) => _missingBootstrapResource('SecureStorage'),
);

final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => _missingBootstrapResource('AppDatabase'),
);

final cacheBoxProvider = Provider<Box<dynamic>>(
  (ref) => ref.watch(appDatabaseProvider).cacheBox,
);

final pendingRequestsBoxProvider = Provider<Box<dynamic>>(
  (ref) => ref.watch(appDatabaseProvider).pendingRequestsBox,
);

final overtimeBoxProvider = Provider<Box<dynamic>>(
  (ref) => ref.watch(appDatabaseProvider).overtimeBox,
);

final authEventBusProvider = Provider<AuthEventBus>(
  (ref) => _missingBootstrapResource('AuthEventBus'),
);

final networkMonitorProvider = Provider<NetworkMonitor>(
  (ref) => _missingBootstrapResource('NetworkMonitor'),
);

final syncEngineProvider = Provider<SyncEngine>(
  (ref) => _missingBootstrapResource('SyncEngine'),
);

final networkClientProvider = Provider<NetworkClient>(
  (ref) => _missingBootstrapResource('NetworkClient'),
);

final dioProvider = Provider<Dio>(
  (ref) => ref.watch(networkClientProvider).dio,
);

final genericSyncProcessorProvider = Provider<GenericSyncProcessor>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return GenericSyncProcessor(
    pendingRequestsBox: ref.watch(pendingRequestsBoxProvider),
    handler: DioPendingRequestHandler(
      ref.watch(dioProvider),
      authenticatedTokenProvider: () => AuthenticatedToken.read(secureStorage),
    ),
  );
});

final foregroundSyncCoordinatorProvider = Provider<ForegroundSyncCoordinator>((
  ref,
) {
  final coordinator = ForegroundSyncCoordinator(
    syncEngine: ref.watch(syncEngineProvider),
    processPendingRequests: ref
        .watch(genericSyncProcessorProvider)
        .processPendingRequests,
  );
  ref.onDispose(() => unawaited(coordinator.dispose()));
  return coordinator;
});

final imageCacheManagerProvider = Provider<ImageCacheManager>(
  (ref) => _missingBootstrapResource('ImageCacheManager'),
);

List<Override> createCoreProviderOverrides({
  required SharedPreferences preferences,
  required AppDatabase database,
  required SecureStorage secureStorage,
  required AuthEventBus authEventBus,
  required NetworkMonitor networkMonitor,
  required SyncEngine syncEngine,
  required NetworkClient networkClient,
  required ImageCacheManager imageCacheManager,
}) => <Override>[
  sharedPreferencesProvider.overrideWithValue(preferences),
  appDatabaseProvider.overrideWith((ref) {
    ref.onDispose(() => unawaited(database.close()));
    return database;
  }),
  secureStorageProvider.overrideWithValue(secureStorage),
  authEventBusProvider.overrideWith((ref) {
    ref.onDispose(() => unawaited(authEventBus.dispose()));
    return authEventBus;
  }),
  networkMonitorProvider.overrideWithValue(networkMonitor),
  syncEngineProvider.overrideWith((ref) {
    ref.onDispose(() => unawaited(syncEngine.dispose()));
    return syncEngine;
  }),
  networkClientProvider.overrideWith((ref) {
    ref.onDispose(networkClient.close);
    return networkClient;
  }),
  imageCacheManagerProvider.overrideWithValue(imageCacheManager),
];

class CoreResourceOwner extends ConsumerWidget {
  const CoreResourceOwner({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref
      ..watch(appDatabaseProvider)
      ..watch(authEventBusProvider)
      ..watch(syncEngineProvider)
      ..watch(foregroundSyncCoordinatorProvider)
      ..watch(networkClientProvider);
    return child;
  }
}

final class AppProviderObserver extends ProviderObserver {
  const AppProviderObserver();

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    AppLogger.error(
      'Provider failure: ${context.provider.name ?? context.provider.runtimeType}',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
