import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cedsif_overtime_mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:cedsif_overtime_mobile/features/overtime/presentation/pages/overtime_review_page.dart';
import 'package:cedsif_overtime_mobile/theme/app_theme.dart';

class _TranslationsLoader extends AssetLoader {
  const _TranslationsLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => {
    'app': {
      'title': 'Portal do FAE',
      'emblem': 'Emblema da República de Moçambique',
    },
    'navigation': {'menu': 'Menu'},
    'overtimeReview': {
      'title': 'Contagem terminada',
      'subtitle': 'Reveja e envie ao e-SNGRHE.',
      'start': 'Início',
      'end': 'Encerramento',
      'registeredTime': 'Tempo registado',
      'submit': 'Enviar ao e-SNGRHE',
      'resume': 'Retomar contagem',
    },
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  Future<void> pumpReview(
    WidgetTester tester, {
    VoidCallback? onSubmit,
    VoidCallback? onResume,
    Widget? drawer,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = OvertimeSession(
      id: 'review',
      startedAt: DateTime(2026, 8, 14, 8, 24),
      endedAt: DateTime(2026, 8, 14, 11, 11),
      status: OvertimeSessionStatus.reviewing,
    );

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('pt')],
        path: 'unused',
        assetLoader: const _TranslationsLoader(),
        fallbackLocale: const Locale('pt'),
        startLocale: const Locale('pt'),
        saveLocale: false,
        child: Builder(
          builder: (context) => MaterialApp(
            theme: AppTheme.light,
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: OvertimeReviewPage(
              session: session,
              elapsed: const Duration(hours: 2, minutes: 47),
              onSubmit: onSubmit,
              onResume: onResume,
              drawer: drawer,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the frozen session summary and both decisions', (
    tester,
  ) async {
    await pumpReview(tester);

    expect(find.text('Contagem terminada'), findsOneWidget);
    expect(find.text('Reveja e envie ao e-SNGRHE.'), findsOneWidget);
    expect(find.text('Início'), findsOneWidget);
    expect(find.text('08:24'), findsOneWidget);
    expect(find.text('Encerramento'), findsOneWidget);
    expect(find.text('11:11'), findsOneWidget);
    expect(find.text('Tempo registado'), findsOneWidget);
    expect(find.text('02:47:00'), findsOneWidget);
    expect(find.text('Enviar ao e-SNGRHE'), findsOneWidget);
    expect(find.text('Retomar contagem'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('forwards the authenticated session drawer', (tester) async {
    const drawer = Drawer(child: Text('Terminar sessão'));

    await pumpReview(tester, drawer: drawer);

    expect(tester.widget<Scaffold>(find.byType(Scaffold)).drawer, drawer);
  });

  testWidgets('submit and resume actions invoke their callbacks', (
    tester,
  ) async {
    var submissions = 0;
    var resumes = 0;
    await pumpReview(
      tester,
      onSubmit: () => submissions++,
      onResume: () => resumes++,
    );

    await tester.tap(find.text('Enviar ao e-SNGRHE'));
    await tester.tap(find.text('Retomar contagem'));

    expect(submissions, 1);
    expect(resumes, 1);
  });
}
