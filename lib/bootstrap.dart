import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cedsif_overtime_mobile/app.dart';
import 'package:cedsif_overtime_mobile/core/config/environment_config.dart';
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
import 'package:cedsif_overtime_mobile/core/utils/analytics_service.dart';
import 'package:cedsif_overtime_mobile/core/utils/log_redactor.dart';
import 'package:cedsif_overtime_mobile/core/utils/logger.dart';

typedef FatalCapture =
    Future<void> Function(Object error, StackTrace stackTrace);
typedef FirebaseInitializer = Future<void> Function();
typedef AnalyticsFactory = FirebaseAnalytics Function();

final class BootstrapStatus {
  bool sentryReady = false;
}

bool shouldEnableSentry({required bool isDebug, required String dsn}) =>
    !isDebug && dsn.trim().isNotEmpty;

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

Future<void> reportFatalError(
  Object error,
  StackTrace stackTrace, {
  required bool sentryEnabled,
  FatalCapture captureException = _captureWithSentry,
}) async {
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
  if (sentryEnabled) {
    await runNonCriticalStep<void>(
      'sentry.capture',
      () => captureException(safeError, safeStackTrace),
    );
  }
}

Future<void> _captureWithSentry(Object error, StackTrace stackTrace) async {
  await Sentry.captureException(error, stackTrace: stackTrace);
}

Future<void> initializeSentryStatus(
  BootstrapStatus status, {
  required bool enabled,
  required Future<void> Function() initializer,
}) async {
  if (!enabled) {
    return;
  }
  final initialized =
      await runNonCriticalStep<bool>('sentry.initialize', () async {
        await initializer();
        return true;
      }) ??
      false;
  status.sentryReady = initialized;
}

Future<void> initializeFirebaseAfterApp({
  required VoidCallback appRunner,
  required FirebaseInitializer initializeFirebase,
  required AnalyticsFactory analyticsFactory,
  required AnalyticsService analyticsService,
}) {
  appRunner();
  return _initializeFirebaseAndAnalytics(
    initializeFirebase: initializeFirebase,
    analyticsFactory: analyticsFactory,
    analyticsService: analyticsService,
  );
}

Future<void> _initializeFirebaseAndAnalytics({
  required FirebaseInitializer initializeFirebase,
  required AnalyticsFactory analyticsFactory,
  required AnalyticsService analyticsService,
}) async {
  final initialized =
      await runNonCriticalStep<bool>('firebase', () async {
        await initializeFirebase();
        return true;
      }) ??
      false;
  if (!initialized || !analyticsService.enabled) {
    return;
  }
  final analytics = await runNonCriticalStep<FirebaseAnalytics>(
    'firebase_analytics',
    () async => analyticsFactory(),
  );
  if (analytics != null) {
    analyticsService.attach(analytics);
  }
}

Widget buildBootstrapRoot(List<Override> overrides) => EasyLocalization(
  supportedLocales: const <Locale>[Locale('en'), Locale('es')],
  path: 'assets/translations',
  fallbackLocale: const Locale('en'),
  child: ProviderScope(
    overrides: overrides,
    observers: const <ProviderObserver>[AppProviderObserver()],
    child: const HorasExtrasApp(),
  ),
);

void bootstrap() {
  final status = BootstrapStatus();
  runZonedGuarded(
    () async {
      await initializeApplication(status: status);
    },
    (error, stackTrace) {
      unawaited(
        reportFatalError(error, stackTrace, sentryEnabled: status.sentryReady),
      );
    },
  );
}

Future<bool> initializeApplication({BootstrapStatus? status}) async {
  final bootstrapStatus = status ?? BootstrapStatus();
  WidgetsFlutterBinding.ensureInitialized();
  await runNonCriticalStep<void>(
    'localization',
    EasyLocalization.ensureInitialized,
  );
  await runNonCriticalStep<void>('system_ui', () async {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: AppColors.primary),
    );
  });

  final sentryEnabled = shouldEnableSentry(
    isDebug: kDebugMode,
    dsn: EnvironmentConfig.sentryDsn,
  );
  await initializeSentryStatus(
    bootstrapStatus,
    enabled: sentryEnabled,
    initializer: () => SentryFlutter.init((options) {
      options.dsn = EnvironmentConfig.sentryDsn;
      options.environment = EnvironmentConfig.environment.name;
    }),
  );

  FlutterError.onError = (details) {
    unawaited(
      reportFatalError(
        details.exception,
        details.stack ?? StackTrace.current,
        sentryEnabled: bootstrapStatus.sentryReady,
      ),
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
  final analyticsService = AnalyticsService(
    enabled: EnvironmentConfig.enableAnalytics,
  );

  final overrides = <Override>[
    secureStorageProvider.overrideWithValue(secureStorage),
    authEventBusProvider.overrideWithValue(authEventBus),
    networkMonitorProvider.overrideWithValue(networkMonitor),
    syncEngineProvider.overrideWithValue(syncEngine),
    imageCacheManagerProvider.overrideWithValue(imageCacheManager),
    analyticsServiceProvider.overrideWithValue(analyticsService),
  ];
  if (preferences != null) {
    overrides.add(sharedPreferencesProvider.overrideWithValue(preferences));
  }
  if (database != null) {
    final networkClient = NetworkClient.create(
      secureStorage: secureStorage,
      authEventBus: authEventBus,
      networkMonitor: networkMonitor,
      cacheBox: database.cacheBox,
    );
    overrides
      ..add(appDatabaseProvider.overrideWithValue(database))
      ..add(networkClientProvider.overrideWithValue(networkClient));
  }

  await runNonCriticalStep<void>('workmanager', () async {
    final worker = BackgroundSyncWorker();
    await worker.initialize();
    await worker.registerPeriodicSync();
  });

  unawaited(
    initializeFirebaseAfterApp(
      appRunner: () => runApp(buildBootstrapRoot(overrides)),
      initializeFirebase: _initializeFirebase,
      analyticsFactory: () => FirebaseAnalytics.instance,
      analyticsService: analyticsService,
    ),
  );
  return bootstrapStatus.sentryReady;
}

Future<void> _initializeFirebase() async {
  final hasDartDefineOptions =
      EnvironmentConfig.firebaseApiKey.isNotEmpty &&
      EnvironmentConfig.firebaseAppId.isNotEmpty &&
      EnvironmentConfig.firebaseMessagingSenderId.isNotEmpty &&
      EnvironmentConfig.firebaseProjectId.isNotEmpty;
  await Firebase.initializeApp(
    options: hasDartDefineOptions
        ? FirebaseOptions(
            apiKey: EnvironmentConfig.firebaseApiKey,
            appId: EnvironmentConfig.firebaseAppId,
            messagingSenderId: EnvironmentConfig.firebaseMessagingSenderId,
            projectId: EnvironmentConfig.firebaseProjectId,
            storageBucket: EnvironmentConfig.firebaseStorageBucket.isEmpty
                ? null
                : EnvironmentConfig.firebaseStorageBucket,
          )
        : null,
  );
}
