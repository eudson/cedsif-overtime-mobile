import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'package:cedsif_overtime_mobile/core/config/router.dart';
import 'package:cedsif_overtime_mobile/core/constants/constants.dart';
import 'package:cedsif_overtime_mobile/core/error/failures.dart';
import 'package:cedsif_overtime_mobile/features/auth/presentation/pages/facial_validation_stub_page.dart';
import 'package:cedsif_overtime_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:cedsif_overtime_mobile/features/history/presentation/pages/history_page.dart';
import 'package:cedsif_overtime_mobile/features/home/presentation/pages/home_page.dart';
import 'package:cedsif_overtime_mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:cedsif_overtime_mobile/features/overtime/domain/repositories/overtime_repository.dart';
import 'package:cedsif_overtime_mobile/features/overtime/presentation/providers/overtime_provider.dart';
import 'package:cedsif_overtime_mobile/widgets/app_button.dart';

class _MemoryOvertimeRepository implements OvertimeRepository {
  OvertimeSession? active;
  final List<OvertimeSession> history = [];

  @override
  Future<Either<Failure, OvertimeSnapshot>> load() async =>
      Right(OvertimeSnapshot(activeSession: active, history: List.of(history)));

  @override
  Future<Either<Failure, OvertimeSession>> start(DateTime startedAt) async {
    active = OvertimeSession(
      id: 'demo',
      startedAt: startedAt,
      status: OvertimeSessionStatus.active,
    );
    return Right(active!);
  }

  @override
  Future<Either<Failure, OvertimeSession>> pause(DateTime pausedAt) async {
    active = active!.pauseAt(pausedAt);
    return Right(active!);
  }

  @override
  Future<Either<Failure, OvertimeSession>> resume(DateTime resumedAt) async {
    active = active!.resumeAt(resumedAt);
    return Right(active!);
  }

  @override
  Future<Either<Failure, OvertimeSnapshot>> submit() async {
    history.insert(0, active!.submit());
    active = null;
    return Right(OvertimeSnapshot(history: List.of(history)));
  }
}

class _SessionRefresh extends ChangeNotifier {
  void trigger() => notifyListeners();
}

ProviderScope _testScope(Widget child, {OvertimeRepository? repository}) =>
    ProviderScope(
      overrides: [
        overtimeRepositoryProvider.overrideWithValue(
          repository ?? _MemoryOvertimeRepository(),
        ),
        overtimeClockProvider.overrideWithValue(
          () => DateTime(2026, 8, 13, 10),
        ),
      ],
      child: child,
    );

void main() {
  Future<bool> validSession() async => true;
  Future<bool> missingSession() async => false;

  testWidgets('splash advances to the Login page', (tester) async {
    final router = createAppRouter(hasValidSession: missingSession);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      _testScope(MaterialApp.router(routerConfig: router)),
    );
    expect(router.state.uri.path, RouteConstants.splash);

    await tester.pump(AppConstants.splashDuration);
    await tester.pumpAndSettle();

    expect(router.state.uri.path, RouteConstants.login);
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('protects application routes without a valid session', (
    tester,
  ) async {
    final router = createAppRouter(
      initialLocation: RouteConstants.home,
      hasValidSession: missingSession,
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      _testScope(MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    expect(router.state.uri.path, RouteConstants.login);
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('skips login while the cached JWT remains valid', (tester) async {
    final router = createAppRouter(
      initialLocation: RouteConstants.login,
      hasValidSession: validSession,
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      _testScope(MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    expect(router.state.uri.path, RouteConstants.facialValidation);
    expect(find.byType(FacialValidationStubPage), findsOneWidget);
  });

  testWidgets('closes an active offline session when its TTL expires', (
    tester,
  ) async {
    var valid = true;
    final refresh = _SessionRefresh();
    final router = createAppRouter(
      initialLocation: RouteConstants.home,
      hasValidSession: () async => valid,
      sessionRefresh: refresh,
    );
    addTearDown(router.dispose);
    addTearDown(refresh.dispose);

    await tester.pumpWidget(
      _testScope(MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();
    expect(router.state.uri.path, RouteConstants.home);

    valid = false;
    refresh.trigger();
    await tester.pumpAndSettle();

    expect(router.state.uri.path, RouteConstants.login);
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('exposes facial-validation and Home destinations', (
    tester,
  ) async {
    final router = createAppRouter(
      initialLocation: RouteConstants.login,
      hasValidSession: validSession,
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      _testScope(MaterialApp.router(routerConfig: router)),
    );
    router.go(RouteConstants.facialValidation);
    await tester.pumpAndSettle();
    expect(find.byType(FacialValidationStubPage), findsOneWidget);

    router.go(RouteConstants.home);
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);

    router.go(RouteConstants.history);
    await tester.pumpAndSettle();
    expect(find.byType(HistoryPage), findsOneWidget);
  });

  testWidgets('facial-validation Continue action opens Home', (tester) async {
    final router = createAppRouter(
      initialLocation: RouteConstants.facialValidation,
      hasValidSession: validSession,
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      _testScope(MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FacialValidationStubPage), findsOneWidget);
    expect(find.byType(AppButton), findsOneWidget);

    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, RouteConstants.home);
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('bottom navigation moves between Home and History', (
    tester,
  ) async {
    final router = createAppRouter(
      initialLocation: RouteConstants.home,
      hasValidSession: validSession,
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      _testScope(MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('navigation.history'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, RouteConstants.history);
    expect(find.byType(HistoryPage), findsOneWidget);

    await tester.tap(find.text('navigation.home'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, RouteConstants.home);
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('stop opens review and submit persists a pending History entry', (
    tester,
  ) async {
    final repository = _MemoryOvertimeRepository();
    final router = createAppRouter(
      initialLocation: RouteConstants.home,
      hasValidSession: validSession,
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      _testScope(
        MaterialApp.router(routerConfig: router),
        repository: repository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('home-start-button')));
    await tester.pump();
    expect(find.text('home.stop'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-running-timer')), findsOneWidget);

    await tester.tap(find.text('home.stop'));
    await tester.pump();
    expect(find.text('overtimeReview.title'), findsOneWidget);
    expect(repository.history, isEmpty);

    await tester.tap(find.text('overtimeReview.submit'));
    await tester.pump();
    expect(repository.history, hasLength(1));
    expect(repository.history.single.status, OvertimeSessionStatus.pending);

    router.go(RouteConstants.history);
    await tester.pumpAndSettle();
    expect(
      find.text('13 calendar.months.8 · calendar.weekdays.4'),
      findsOneWidget,
    );
    expect(find.text('10:00 → 10:00 · 00:00'), findsOneWidget);
  });

  testWidgets('review can resume the same counting session', (tester) async {
    final repository = _MemoryOvertimeRepository();
    final router = createAppRouter(
      initialLocation: RouteConstants.home,
      hasValidSession: validSession,
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      _testScope(
        MaterialApp.router(routerConfig: router),
        repository: repository,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('home-start-button')));
    await tester.pump();
    await tester.tap(find.text('home.stop'));
    await tester.pump();

    await tester.tap(find.text('overtimeReview.resume'));
    await tester.pump();

    expect(find.text('home.stop'), findsOneWidget);
    expect(repository.active?.status, OvertimeSessionStatus.active);
    expect(repository.history, isEmpty);
  });

  testWidgets('restores a persisted review session after rebuilding Home', (
    tester,
  ) async {
    final repository = _MemoryOvertimeRepository()
      ..active = OvertimeSession(
        id: 'persisted-review',
        startedAt: DateTime(2026, 8, 13, 9),
        endedAt: DateTime(2026, 8, 13, 10),
        status: OvertimeSessionStatus.reviewing,
      );
    final router = createAppRouter(
      initialLocation: RouteConstants.home,
      hasValidSession: validSession,
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      _testScope(
        MaterialApp.router(routerConfig: router),
        repository: repository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('overtimeReview.title'), findsOneWidget);
    expect(find.text('overtimeReview.submit'), findsOneWidget);
    expect(find.text('overtimeReview.resume'), findsOneWidget);
  });
}
