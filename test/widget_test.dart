import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cedsif_overtime_mobile/app.dart';
import 'package:cedsif_overtime_mobile/bootstrap.dart';
import 'package:cedsif_overtime_mobile/core/config/providers.dart';
import 'package:cedsif_overtime_mobile/core/config/router.dart';
import 'package:cedsif_overtime_mobile/core/constants/constants.dart';
import 'package:cedsif_overtime_mobile/core/network/auth_event_bus.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('bootstrap root reaches the production application', (
    tester,
  ) async {
    final eventBus = AuthEventBus();
    final router = createAppRouter(initialLocation: RouteConstants.home);
    addTearDown(eventBus.dispose);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      buildBootstrapRoot([
        authEventBusProvider.overrideWithValue(eventBus),
        routerProvider.overrideWithValue(router),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HorasExtrasApp), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
