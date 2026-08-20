import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cedsif_overtime_mobile/core/error/failures.dart';
import 'package:cedsif_overtime_mobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:cedsif_overtime_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:cedsif_overtime_mobile/features/auth/presentation/providers/login_provider.dart';
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
      'invalidCredentials': 'NUIT ou senha inválidos',
    },
  };
}

class _MockLoginUseCase extends Mock implements LoginUseCase {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  Future<void> pumpLogin(
    WidgetTester tester, {
    VoidCallback? onAuthenticated,
    LoginUseCase? loginUseCase,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final resolvedUseCase = loginUseCase ?? _MockLoginUseCase();
    if (loginUseCase == null) {
      when(
        () => resolvedUseCase(
          nuit: any(named: 'nuit'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Right<Failure, Unit>(unit));
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          loginUseCaseProvider.overrideWithValue(resolvedUseCase),
        ],
        child: EasyLocalization(
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
    final useCase = _MockLoginUseCase();
    final completer = Completer<Either<Failure, Unit>>();
    when(
      () => useCase(nuit: '100234567', password: 'segredo'),
    ).thenAnswer((_) => completer.future);
    await pumpLogin(
      tester,
      onAuthenticated: () => completions++,
      loginUseCase: useCase,
    );

    await tester.enterText(find.byType(TextFormField).first, '100234567');
    await tester.enterText(find.byType(TextFormField).last, 'segredo');
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(AppButton));
    completer.complete(const Right<Failure, Unit>(unit));
    await tester.pump();
    expect(completions, 1);
    verify(() => useCase(nuit: '100234567', password: 'segredo')).called(1);
  });

  testWidgets('shows the typed login failure without navigating', (
    tester,
  ) async {
    var completions = 0;
    final useCase = _MockLoginUseCase();
    when(() => useCase(nuit: '100234567', password: 'wrong')).thenAnswer(
      (_) async => const Left<Failure, Unit>(
        AuthFailure('auth.invalidCredentials', code: '401'),
      ),
    );
    await pumpLogin(
      tester,
      onAuthenticated: () => completions++,
      loginUseCase: useCase,
    );

    await tester.enterText(find.byType(TextFormField).first, '100234567');
    await tester.enterText(find.byType(TextFormField).last, 'wrong');
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('NUIT ou senha inválidos'), findsOneWidget);
    expect(completions, 0);
  });
}
