import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cedsif_overtime_mobile/features/history/presentation/models/history_entry.dart';
import 'package:cedsif_overtime_mobile/features/history/presentation/pages/history_page.dart';
import 'package:cedsif_overtime_mobile/features/history/presentation/widgets/history_entry_card.dart';
import 'package:cedsif_overtime_mobile/theme/app_theme.dart';
import 'package:cedsif_overtime_mobile/widgets/status_chip.dart';

class _HistoryTranslationsLoader extends AssetLoader {
  const _HistoryTranslationsLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => {
    'app': {
      'title': 'Portal do FAE',
      'emblem': 'Emblema da República de Moçambique',
    },
    'history': {'title': 'Histórico'},
    'navigation': {
      'home': 'Início',
      'history': 'Histórico',
      'profile': 'Perfil',
      'menu': 'Menu',
    },
    'status': {'pending': 'Pendente', 'approved': 'Aprovada'},
  };
}

void main() {
  const entries = <HistoryEntry>[
    HistoryEntry(
      dateLabel: '18 Jul · Sex',
      startTime: '08:24',
      endTime: '11:11',
      duration: '02:47',
      status: AppStatus.pendente,
    ),
  ];
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  Future<void> pumpHistory(
    WidgetTester tester, {
    List<HistoryEntry>? entries,
    Widget? drawer,
    bool isLoading = false,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('pt')],
        path: 'unused',
        assetLoader: const _HistoryTranslationsLoader(),
        fallbackLocale: const Locale('pt'),
        startLocale: const Locale('pt'),
        saveLocale: false,
        child: Builder(
          builder: (context) => MaterialApp(
            theme: AppTheme.light,
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: HistoryPage(
              entries: entries ?? const [],
              isLoading: isLoading,
              drawer: drawer,
            ),
          ),
        ),
      ),
    );
    if (isLoading) {
      await tester.pump();
      await tester.pump();
    } else {
      await tester.pumpAndSettle();
    }
  }

  testWidgets('renders the approved History records and selected navigation', (
    tester,
  ) async {
    await pumpHistory(tester, entries: entries);

    expect(find.text('Portal do FAE'), findsOneWidget);
    expect(find.text('Histórico'), findsNWidgets(2));
    expect(find.text('18 Jul · Sex'), findsOneWidget);
    expect(find.text('08:24 → 11:11 · 02:47'), findsOneWidget);
    expect(find.text('Pendente'), findsOneWidget);

    expect(
      find.byWidgetPredicate(
        (widget) => widget is StatusChip && widget.status == AppStatus.pendente,
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders an injected empty History list without cards', (
    tester,
  ) async {
    await pumpHistory(tester, entries: const []);

    expect(find.text('Histórico'), findsNWidgets(2));
    expect(find.byType(HistoryEntryCard), findsNothing);
  });

  testWidgets('renders progress while API-backed history is loading', (
    tester,
  ) async {
    await pumpHistory(tester, isLoading: true);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(HistoryEntryCard), findsNothing);
  });

  testWidgets('forwards the authenticated session drawer', (tester) async {
    const drawer = Drawer(child: Text('Terminar sessão'));

    await pumpHistory(tester, drawer: drawer);

    expect(tester.widget<Scaffold>(find.byType(Scaffold)).drawer, drawer);
  });
}
