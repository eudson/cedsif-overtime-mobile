import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cedsif_overtime_mobile/core/config/providers.dart';
import 'package:cedsif_overtime_mobile/core/database/app_database.dart';
import 'package:cedsif_overtime_mobile/core/network/auth_event_bus.dart';
import 'package:cedsif_overtime_mobile/core/network/network_client.dart';
import 'package:cedsif_overtime_mobile/core/network/network_monitor.dart';
import 'package:cedsif_overtime_mobile/core/storage/image_cache_manager.dart';
import 'package:cedsif_overtime_mobile/core/storage/secure_storage.dart';
import 'package:cedsif_overtime_mobile/core/sync/sync_engine.dart';
import 'package:cedsif_overtime_mobile/core/utils/analytics_service.dart';

class _MockDatabase extends Mock implements AppDatabase {}

class _MockBox extends Mock implements Box<dynamic> {}

class _MockSecureStorage extends Mock implements SecureStorage {}

class _MockNetworkMonitor extends Mock implements NetworkMonitor {}

class _MockNetworkClient extends Mock implements NetworkClient {}

class _MockImageCacheManager extends Mock implements ImageCacheManager {}

class _MockSyncEngine extends Mock implements SyncEngine {}

void main() {
  test('bootstrap-owned providers require explicit overrides', () {
    final providers = <ProviderListenable<Object?>>[
      sharedPreferencesProvider,
      secureStorageProvider,
      appDatabaseProvider,
      authEventBusProvider,
      networkMonitorProvider,
      syncEngineProvider,
      networkClientProvider,
      imageCacheManagerProvider,
      analyticsServiceProvider,
    ];

    for (final provider in providers) {
      final container = ProviderContainer();
      expect(
        () => container.read(provider),
        throwsA(
          isA<ProviderException>().having(
            (error) => error.exception,
            'exception',
            isA<UnimplementedError>(),
          ),
        ),
        reason: provider.toString(),
      );
      container.dispose();
    }
  });

  test('bootstrap overrides expose every initialized core resource', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final database = _MockDatabase();
    final cacheBox = _MockBox();
    final pendingBox = _MockBox();
    when(() => database.cacheBox).thenReturn(cacheBox);
    when(() => database.pendingRequestsBox).thenReturn(pendingBox);
    final secureStorage = _MockSecureStorage();
    final authEventBus = AuthEventBus();
    final networkMonitor = _MockNetworkMonitor();
    final syncEngine = SyncEngine(
      connectivityChanges: const Stream<bool>.empty(),
      initiallyOnline: true,
    );
    final networkClient = _MockNetworkClient();
    final imageCacheManager = _MockImageCacheManager();
    final analyticsService = AnalyticsService(enabled: false);
    when(() => database.close()).thenAnswer((_) async {});
    when(() => networkClient.close()).thenReturn(null);
    final container = ProviderContainer(
      overrides: createCoreProviderOverrides(
        preferences: preferences,
        database: database,
        secureStorage: secureStorage,
        authEventBus: authEventBus,
        networkMonitor: networkMonitor,
        syncEngine: syncEngine,
        networkClient: networkClient,
        imageCacheManager: imageCacheManager,
        analyticsService: analyticsService,
      ),
    );
    addTearDown(container.dispose);

    expect(container.read(sharedPreferencesProvider), same(preferences));
    expect(container.read(localStorageProvider), isNotNull);
    expect(container.read(secureStorageProvider), same(secureStorage));
    expect(container.read(appDatabaseProvider), same(database));
    expect(container.read(cacheBoxProvider), same(cacheBox));
    expect(container.read(pendingRequestsBoxProvider), same(pendingBox));
    expect(container.read(authEventBusProvider), same(authEventBus));
    expect(container.read(networkMonitorProvider), same(networkMonitor));
    expect(container.read(syncEngineProvider), same(syncEngine));
    expect(container.read(networkClientProvider), same(networkClient));
    expect(container.read(imageCacheManagerProvider), same(imageCacheManager));
    expect(container.read(analyticsServiceProvider), same(analyticsService));
  });

  test('bootstrap overrides release owned resources on disposal', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final database = _MockDatabase();
    final secureStorage = _MockSecureStorage();
    final authEventBus = AuthEventBus();
    final networkMonitor = _MockNetworkMonitor();
    final syncEngine = _MockSyncEngine();
    final networkClient = _MockNetworkClient();
    final imageCacheManager = _MockImageCacheManager();
    final analyticsService = AnalyticsService(enabled: false);
    when(() => database.close()).thenAnswer((_) async {});
    when(() => syncEngine.dispose()).thenAnswer((_) async {});
    when(() => networkClient.close()).thenReturn(null);

    final container = ProviderContainer(
      overrides: createCoreProviderOverrides(
        preferences: preferences,
        database: database,
        secureStorage: secureStorage,
        authEventBus: authEventBus,
        networkMonitor: networkMonitor,
        syncEngine: syncEngine,
        networkClient: networkClient,
        imageCacheManager: imageCacheManager,
        analyticsService: analyticsService,
      ),
    );
    container
      ..read(appDatabaseProvider)
      ..read(authEventBusProvider)
      ..read(syncEngineProvider)
      ..read(networkClientProvider)
      ..dispose();
    await Future<void>.delayed(Duration.zero);

    verify(() => database.close()).called(1);
    verify(() => syncEngine.dispose()).called(1);
    verify(() => networkClient.close()).called(1);
  });
}
