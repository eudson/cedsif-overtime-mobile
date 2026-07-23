import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cedsif_overtime_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:cedsif_overtime_mobile/theme/app_spacing.dart';
import 'package:cedsif_overtime_mobile/theme/app_theme.dart';
import 'package:cedsif_overtime_mobile/widgets/app_button.dart';
import 'package:cedsif_overtime_mobile/widgets/app_text_field.dart';

class _LoginTranslationsLoader extends AssetLoader {
  const _LoginTranslationsLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => {
    'app': {
      'title': 'Portal do FAE',
      'emblem': 'Emblema da República de Moçambique',
    },
    'auth': {
      'subtitle': 'Registo de horas extraordinárias',
      'nuit': 'NUIT',
      'password': 'Senha',
      'enter': 'Entrar',
      'forgotPassword': 'Esqueceu a senha?',
      'required': 'Campo obrigatório',
      'invalidNuit': 'Introduza um NUIT válido de 9 dígitos',
    },
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  Future<void> pumpLogin(
    WidgetTester tester, {
    VoidCallback? onAuthenticated,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('pt')],
        path: 'unused',
        assetLoader: const _LoginTranslationsLoader(),
        fallbackLocale: const Locale('pt'),
        startLocale: const Locale('pt'),
        saveLocale: false,
        child: Builder(
          builder: (context) => MaterialApp(
            theme: AppTheme.light,
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: LoginPage(onAuthenticated: onAuthenticated),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('matches the supplied Login content and field behavior', (
    tester,
  ) async {
    await pumpLogin(tester);

    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.text('Portal do FAE'), findsOneWidget);
    expect(find.text('Registo de horas extraordinárias'), findsOneWidget);
    expect(find.text('NUIT'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Esqueceu a senha?'), findsOneWidget);
    expect(find.byType(AppTextField), findsNWidgets(2));

    final fields = tester.widgetList<EditableText>(find.byType(EditableText));
    expect(fields.first.keyboardType, TextInputType.number);
    expect(fields.last.obscureText, isTrue);
    expect(
      tester.getSize(find.byType(FilledButton)).height,
      AppSpacing.buttonHeight,
    );
  });

  testWidgets('validates required fields and a nine-digit NUIT', (
    tester,
  ) async {
    await pumpLogin(tester);

    await tester.tap(find.text('Entrar'));
    await tester.pump();
    expect(find.text('Campo obrigatório'), findsNWidgets(2));

    await tester.enterText(find.byType(TextFormField).first, '123');
    await tester.enterText(find.byType(TextFormField).last, 'segredo');
    await tester.tap(find.text('Entrar'));
    await tester.pump();
    expect(find.text('Introduza um NUIT válido de 9 dígitos'), findsOneWidget);
  });

  testWidgets('locks duplicate submission while loading and completes once', (
    tester,
  ) async {
    var completions = 0;
    await pumpLogin(tester, onAuthenticated: () => completions++);

    await tester.enterText(find.byType(TextFormField).first, '100234567');
    await tester.enterText(find.byType(TextFormField).last, 'segredo');
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(AppButton));
    await tester.pump(AppSpacing.loginLoadingDuration);
    await tester.pump();
    expect(completions, 1);
  });
}
