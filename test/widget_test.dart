import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cedsif_overtime_mobile/app.dart';
import 'package:cedsif_overtime_mobile/bootstrap.dart';
import 'package:cedsif_overtime_mobile/core/config/providers.dart';
import 'package:cedsif_overtime_mobile/core/config/router.dart';
import 'package:cedsif_overtime_mobile/core/constants/constants.dart';
import 'package:cedsif_overtime_mobile/core/database/app_database.dart';
import 'package:cedsif_overtime_mobile/core/network/auth_event_bus.dart';
import 'package:cedsif_overtime_mobile/core/network/network_client.dart';
import 'package:cedsif_overtime_mobile/core/sync/sync_engine.dart';

class _MockAppDatabase extends Mock implements AppDatabase {}

class _MockNetworkClient extends Mock implements NetworkClient {}

class _MockSyncEngine extends Mock implements SyncEngine {}

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
        appDatabaseProvider.overrideWithValue(_MockAppDatabase()),
        networkClientProvider.overrideWithValue(_MockNetworkClient()),
        syncEngineProvider.overrideWithValue(_MockSyncEngine()),
        routerProvider.overrideWithValue(router),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HorasExtrasApp), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
