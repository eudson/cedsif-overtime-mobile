import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cedsif_overtime_mobile/app.dart';
import 'package:cedsif_overtime_mobile/bootstrap.dart';
import 'package:cedsif_overtime_mobile/core/config/providers.dart';
import 'package:cedsif_overtime_mobile/core/config/router.dart';
import 'package:cedsif_overtime_mobile/core/constants/constants.dart';
import 'package:cedsif_overtime_mobile/core/database/app_database.dart';
import 'package:cedsif_overtime_mobile/core/error/failures.dart';
import 'package:cedsif_overtime_mobile/core/network/auth_event_bus.dart';
import 'package:cedsif_overtime_mobile/core/network/network_client.dart';
import 'package:cedsif_overtime_mobile/core/sync/sync_engine.dart';
import 'package:cedsif_overtime_mobile/core/sync/foreground_sync_coordinator.dart';
import 'package:cedsif_overtime_mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:cedsif_overtime_mobile/features/overtime/domain/entities/device_location.dart';
import 'package:cedsif_overtime_mobile/features/overtime/domain/repositories/overtime_repository.dart';
import 'package:cedsif_overtime_mobile/features/overtime/presentation/providers/overtime_provider.dart';
import 'package:cedsif_overtime_mobile/features/profile/domain/entities/employee_profile.dart';
import 'package:cedsif_overtime_mobile/features/profile/domain/repositories/profile_repository.dart';
import 'package:cedsif_overtime_mobile/features/profile/presentation/providers/profile_provider.dart';

class _MockAppDatabase extends Mock implements AppDatabase {}

class _MockNetworkClient extends Mock implements NetworkClient {}

class _MockSyncEngine extends Mock implements SyncEngine {}

class _FakeOvertimeRepository implements OvertimeRepository {
  @override
  Future<Either<Failure, OvertimeSnapshot>> load() async =>
      const Right(OvertimeSnapshot(history: []));

  @override
  Future<Either<Failure, OvertimeSession>> start({
    required DateTime startedAt,
    required DeviceLocation location,
    required String biometricReference,
  }) async => Right(
    OvertimeSession(
      id: 'fake',
      startedAt: startedAt,
      status: OvertimeSessionStatus.active,
    ),
  );

  @override
  Future<Either<Failure, OvertimeSession>> pause(DateTime pausedAt) async =>
      const Left(CacheFailure('errors.generic'));

  @override
  Future<Either<Failure, OvertimeSession>> resume(DateTime resumedAt) async =>
      const Left(CacheFailure('errors.generic'));

  @override
  Future<Either<Failure, OvertimeSnapshot>> submit() async =>
      const Right(OvertimeSnapshot(history: []));
}

class _FakeProfileRepository implements ProfileRepository {
  @override
  Future<Either<Failure, EmployeeProfile>> get() async =>
      const Right<Failure, EmployeeProfile>(
        EmployeeProfile(
          id: 'employee-id',
          nuit: '123456789',
          firstName: 'Ana',
          lastName: 'Mucavele',
        ),
      );
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('bootstrap root reaches the production application', (
    tester,
  ) async {
    final eventBus = AuthEventBus();
    final testSyncEngine = SyncEngine(
      connectivityChanges: const Stream<bool>.empty(),
      initiallyOnline: false,
    );
    final foregroundSync = ForegroundSyncCoordinator(
      syncEngine: testSyncEngine,
      processPendingRequests: () async => true,
    );
    final router = createAppRouter(
      initialLocation: RouteConstants.home,
      hasValidSession: () async => true,
    );
    addTearDown(eventBus.dispose);
    addTearDown(router.dispose);
    addTearDown(foregroundSync.dispose);
    addTearDown(testSyncEngine.dispose);

    await tester.pumpWidget(
      buildBootstrapRoot([
        authEventBusProvider.overrideWithValue(eventBus),
        appDatabaseProvider.overrideWithValue(_MockAppDatabase()),
        networkClientProvider.overrideWithValue(_MockNetworkClient()),
        syncEngineProvider.overrideWithValue(_MockSyncEngine()),
        foregroundSyncCoordinatorProvider.overrideWithValue(foregroundSync),
        overtimeRepositoryProvider.overrideWithValue(_FakeOvertimeRepository()),
        profileRepositoryProvider.overrideWithValue(_FakeProfileRepository()),
        routerProvider.overrideWithValue(router),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HorasExtrasApp), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
