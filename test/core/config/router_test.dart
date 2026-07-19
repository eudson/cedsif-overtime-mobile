import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cedsif_overtime_mobile/core/config/router.dart';
import 'package:cedsif_overtime_mobile/core/constants/constants.dart';
import 'package:cedsif_overtime_mobile/features/home/presentation/pages/home_page.dart';

class _MockGoRouterState extends Mock implements GoRouterState {}

void main() {
  test('appRedirect is a named pass-through hook', () {
    expect(appRedirect(null, _MockGoRouterState()), isNull);
  });

  testWidgets('splash advances to the production home page', (tester) async {
    final router = createAppRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    expect(router.state.uri.path, RouteConstants.splash);

    await tester.pump(AppConstants.splashDuration);
    await tester.pump();

    expect(router.state.uri.path, RouteConstants.home);
    expect(find.byType(HomePage), findsOneWidget);
  });
}
