import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cedsif_overtime_mobile/app.dart';
import 'package:cedsif_overtime_mobile/core/config/providers.dart';
import 'package:cedsif_overtime_mobile/core/constants/app_colors.dart';
import 'package:cedsif_overtime_mobile/core/database/app_database.dart';
import 'package:cedsif_overtime_mobile/core/network/auth_event_bus.dart';
import 'package:cedsif_overtime_mobile/core/network/network_client.dart';
import 'package:cedsif_overtime_mobile/core/network/network_monitor.dart';
import 'package:cedsif_overtime_mobile/core/storage/image_cache_manager.dart';
import 'package:cedsif_overtime_mobile/core/storage/secure_storage.dart';
import 'package:cedsif_overtime_mobile/core/sync/background_sync_worker.dart';
import 'package:cedsif_overtime_mobile/core/sync/sync_engine.dart';
import 'package:cedsif_overtime_mobile/core/utils/log_redactor.dart';
import 'package:cedsif_overtime_mobile/core/utils/logger.dart';

Future<T?> runNonCriticalStep<T>(
  String name,
  Future<T> Function() operation,
) async {
  try {
    return await operation();
  } on Object catch (error, stackTrace) {
    AppLogger.warning(
      'Bootstrap step failed: $name',
      error: error,
      stackTrace: stackTrace,
    );
    return null;
  }
}

Future<void> reportFatalError(Object error, StackTrace stackTrace) async {
  final safeError =
      LogRedactor.redactObject(error) ?? LogRedactor.redactedValue;
  final safeStackTrace = StackTrace.fromString(
    LogRedactor.redact(stackTrace.toString()),
  );
  AppLogger.error(
    'Fatal application error',
    error: safeError,
    stackTrace: safeStackTrace,
  );
}

Future<void> initializeBackgroundServicesAfterApp({
  required VoidCallback appRunner,
  required Future<void> Function() initializeBackgroundServices,
}) {
  appRunner();
  return runNonCriticalStep<void>(
    'background_services',
    initializeBackgroundServices,
  );
}

Widget buildBootstrapRoot(List<Override> overrides) => EasyLocalization(
  supportedLocales: const <Locale>[Locale('en'), Locale('es')],
  path: 'assets/translations',
  fallbackLocale: const Locale('en'),
  child: ProviderScope(
    overrides: overrides,
    observers: const <ProviderObserver>[AppProviderObserver()],
    child: const CoreResourceOwner(child: HorasExtrasApp()),
  ),
);

Widget buildBootstrapFallbackRoot() => const MaterialApp(
  debugShowCheckedModeBanner: false,
  home: Scaffold(
    body: Center(
      child: Icon(Icons.error_outline, color: AppColors.error, size: 48),
    ),
  ),
);

void bootstrap() {
  runZonedGuarded(initializeApplication, (error, stackTrace) {
    unawaited(reportFatalError(error, stackTrace));
  });
}

Future<void> initializeApplication() async {
  WidgetsFlutterBinding.ensureInitialized();
  final localizationReady =
      await runNonCriticalStep<bool>('localization', () async {
        await EasyLocalization.ensureInitialized();
        return true;
      }) ??
      false;
  if (!localizationReady) {
    runApp(buildBootstrapFallbackRoot());
    return;
  }
  await runNonCriticalStep<void>('system_ui', () async {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: AppColors.primary),
    );
  });

  FlutterError.onError = (details) {
    unawaited(
      reportFatalError(details.exception, details.stack ?? StackTrace.current),
    );
  };

  final database = await runNonCriticalStep<AppDatabase>(
    'database',
    AppDatabase.initialize,
  );
  final preferences = await runNonCriticalStep<SharedPreferences>(
    'shared_preferences',
    SharedPreferences.getInstance,
  );
  if (database == null || preferences == null) {
    await database?.close();
    runApp(buildBootstrapFallbackRoot());
    return;
  }
  final secureStorage = const SecureStorage();
  final authEventBus = AuthEventBus();
  final networkMonitor = NetworkMonitor();
  final initiallyOnline =
      await runNonCriticalStep<bool>(
        'connectivity',
        () => networkMonitor.isOnline,
      ) ??
      false;
  final syncEngine = SyncEngine(
    connectivityChanges: networkMonitor.changes,
    initiallyOnline: initiallyOnline,
  );
  final imageCacheManager = ImageCacheManager.shared;

  final networkClient = NetworkClient.create(
    secureStorage: secureStorage,
    authEventBus: authEventBus,
    networkMonitor: networkMonitor,
    cacheBox: database.cacheBox,
  );
  final overrides = createCoreProviderOverrides(
    preferences: preferences,
    database: database,
    secureStorage: secureStorage,
    authEventBus: authEventBus,
    networkMonitor: networkMonitor,
    syncEngine: syncEngine,
    networkClient: networkClient,
    imageCacheManager: imageCacheManager,
  );

  void appRunner() => runApp(buildBootstrapRoot(overrides));
  unawaited(
    initializeBackgroundServicesAfterApp(
      appRunner: appRunner,
      initializeBackgroundServices: () async {
        final worker = BackgroundSyncWorker();
        await worker.initialize();
        await worker.registerPeriodicSync();
      },
    ),
  );
}
