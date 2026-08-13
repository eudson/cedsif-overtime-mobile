import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cedsif_overtime_mobile/app.dart';
import 'package:cedsif_overtime_mobile/core/config/providers.dart';
import 'package:cedsif_overtime_mobile/core/config/router.dart';
import 'package:cedsif_overtime_mobile/core/constants/constants.dart';
import 'package:cedsif_overtime_mobile/core/error/failures.dart';
import 'package:cedsif_overtime_mobile/core/network/auth_event_bus.dart';
import 'package:cedsif_overtime_mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:cedsif_overtime_mobile/features/overtime/domain/repositories/overtime_repository.dart';
import 'package:cedsif_overtime_mobile/features/overtime/presentation/providers/overtime_provider.dart';

class _FakeOvertimeRepository implements OvertimeRepository {
  @override
  Future<Either<Failure, OvertimeSnapshot>> load() async =>
      const Right(OvertimeSnapshot(history: []));

  @override
  Future<Either<Failure, OvertimeSession>> start(DateTime startedAt) async =>
      Right(
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

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('builds MaterialApp.router and handles session expiry', (
    tester,
  ) async {
    final eventBus = AuthEventBus();
    final router = createAppRouter(initialLocation: RouteConstants.home);
    addTearDown(eventBus.dispose);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const <Locale>[Locale('en'), Locale('es')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        child: ProviderScope(
          overrides: [
            authEventBusProvider.overrideWithValue(eventBus),
            routerProvider.overrideWithValue(router),
            overtimeRepositoryProvider.overrideWithValue(
              _FakeOvertimeRepository(),
            ),
          ],
          child: const HorasExtrasApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    eventBus.emit(AuthEvent.sessionExpired);
    await tester.pump();

    expect(router.state.uri.path, RouteConstants.splash);
  });
}
