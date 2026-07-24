import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cedsif_overtime_mobile/features/home/presentation/pages/home_page.dart';
import 'package:cedsif_overtime_mobile/theme/app_spacing.dart';
import 'package:cedsif_overtime_mobile/theme/app_theme.dart';

class _HomeTranslationsLoader extends AssetLoader {
  const _HomeTranslationsLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => {
    'app': {
      'title': 'Portal do FAE',
      'emblem': 'Emblema da República de Moçambique',
    },
    'home': {
      'greeting': 'Bom dia,',
      'name': 'Ana M. Cossa',
      'identity': 'NUIT 100234567 · DP Maputo',
      'insidePerimeter': 'No perímetro',
      'online': 'Online',
      'notStarted': 'Ainda não iniciou a contagem de hoje',
      'start': 'Iniciar',
      'thisMonth': 'Este mês',
      'approvedHours': 'Horas aprovadas',
      'approvedTotal': '18:30',
    },
    'navigation': {
      'home': 'Início',
      'history': 'Histórico',
      'profile': 'Perfil',
      'menu': 'Menu',
    },
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  Future<void> pumpHome(
    WidgetTester tester, {
    VoidCallback? onStart,
    VoidCallback? onHistorySelected,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('pt')],
        path: 'unused',
        assetLoader: const _HomeTranslationsLoader(),
        fallbackLocale: const Locale('pt'),
        startLocale: const Locale('pt'),
        saveLocale: false,
        child: Builder(
          builder: (context) => MaterialApp(
            theme: AppTheme.light,
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: HomePage(
              onStart: onStart,
              onHistorySelected: onHistorySelected,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the supplied Home identity, statuses, and summary', (
    tester,
  ) async {
    await pumpHome(tester);

    expect(find.text('Portal do FAE'), findsOneWidget);
    expect(find.text('Bom dia,'), findsOneWidget);
    expect(find.text('Ana M. Cossa'), findsOneWidget);
    expect(find.text('NUIT 100234567 · DP Maputo'), findsOneWidget);
    expect(find.text('No perímetro'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
    expect(find.text('Ainda não iniciou a contagem de hoje'), findsOneWidget);
    expect(find.text('Iniciar'), findsOneWidget);
    expect(find.text('Este mês'), findsOneWidget);
    expect(find.text('Horas aprovadas'), findsOneWidget);
    expect(find.text('18:30'), findsOneWidget);
  });

  testWidgets('History destination invokes its navigation hook', (
    tester,
  ) async {
    var historySelections = 0;
    await pumpHome(tester, onHistorySelected: () => historySelections++);

    expect(find.text('Início'), findsOneWidget);
    expect(find.text('Histórico'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
    await tester.tap(find.text('Histórico'));
    expect(historySelections, 1);

    await tester.tap(find.text('Perfil'));
    await tester.pump();
    expect(historySelections, 1);
    expect(find.text('Ana M. Cossa'), findsOneWidget);
  });

  testWidgets('start control is accessible and invokes the navigation hook', (
    tester,
  ) async {
    var starts = 0;
    await pumpHome(tester, onStart: () => starts++);

    final start = find.byKey(const ValueKey('home-start-button'));
    final size = tester.getSize(start);
    expect(size.width, greaterThanOrEqualTo(AppSpacing.touchTarget));
    expect(size.height, greaterThanOrEqualTo(AppSpacing.touchTarget));
    await tester.tap(start);
    expect(starts, 1);
  });
}
