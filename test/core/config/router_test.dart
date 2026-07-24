import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cedsif_overtime_mobile/core/config/router.dart';
import 'package:cedsif_overtime_mobile/core/constants/constants.dart';
import 'package:cedsif_overtime_mobile/features/auth/presentation/pages/facial_validation_stub_page.dart';
import 'package:cedsif_overtime_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:cedsif_overtime_mobile/features/history/presentation/pages/history_page.dart';
import 'package:cedsif_overtime_mobile/features/home/presentation/pages/home_page.dart';
import 'package:cedsif_overtime_mobile/widgets/app_button.dart';

class _MockGoRouterState extends Mock implements GoRouterState {}

void main() {
  test('appRedirect is a named pass-through hook', () {
    expect(appRedirect(null, _MockGoRouterState()), isNull);
  });

  testWidgets('splash advances to the Login page', (tester) async {
    final router = createAppRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    expect(router.state.uri.path, RouteConstants.splash);

    await tester.pump(AppConstants.splashDuration);
    await tester.pump();

    expect(router.state.uri.path, RouteConstants.login);
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('exposes facial-validation and Home destinations', (
    tester,
  ) async {
    final router = createAppRouter(initialLocation: RouteConstants.login);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
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
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );

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
    final router = createAppRouter(initialLocation: RouteConstants.home);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );

    await tester.tap(find.text('navigation.history'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, RouteConstants.history);
    expect(find.byType(HistoryPage), findsOneWidget);

    await tester.tap(find.text('navigation.home'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, RouteConstants.home);
    expect(find.byType(HomePage), findsOneWidget);
  });
}
