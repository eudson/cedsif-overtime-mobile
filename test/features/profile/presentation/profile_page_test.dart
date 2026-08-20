import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cedsif_overtime_mobile/features/profile/domain/entities/employee_profile.dart';
import 'package:cedsif_overtime_mobile/features/profile/presentation/pages/profile_page.dart';

class _ProfileTranslationsLoader extends AssetLoader {
  const _ProfileTranslationsLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => {
    'app': {'title': 'Portal do FAE'},
    'navigation': {
      'home': 'Início',
      'history': 'Histórico',
      'profile': 'Perfil',
      'menu': 'Menu',
    },
    'profile': {
      'title': 'Perfil',
      'nuit': 'NUIT',
      'workUnit': 'Unidade de trabalho',
      'workUnitReference': 'Referência da UGB',
      'unassigned': 'Não atribuída',
    },
    'common': {'retry': 'Tentar novamente'},
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('renders the real employee identity and work unit', (
    tester,
  ) async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const <Locale>[Locale('pt')],
        path: 'unused',
        assetLoader: const _ProfileTranslationsLoader(),
        fallbackLocale: const Locale('pt'),
        startLocale: const Locale('pt'),
        saveLocale: false,
        child: Builder(
          builder: (context) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: const ProfilePage(
              profile: EmployeeProfile(
                id: 'employee-1',
                nuit: '123456789',
                firstName: 'Ana',
                lastName: 'Mucavele',
                workUnit: WorkUnitSummary(
                  id: 'work-unit-1',
                  externalReference: 'UGB-001',
                  name: 'Hospital Central de Maputo',
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ana Mucavele'), findsOneWidget);
    expect(find.text('123456789'), findsOneWidget);
    expect(find.text('Hospital Central de Maputo'), findsOneWidget);
    expect(find.text('UGB-001'), findsOneWidget);
  });
}
