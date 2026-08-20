import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cedsif_overtime_mobile/core/error/failures.dart';
import 'package:cedsif_overtime_mobile/features/auth/domain/usecases/logout_usecase.dart';
import 'package:cedsif_overtime_mobile/features/auth/presentation/providers/login_provider.dart';
import 'package:cedsif_overtime_mobile/features/auth/presentation/widgets/session_menu_drawer.dart';

class _MockLogoutUseCase extends Mock implements LogoutUseCase {}

class _MenuTranslationsLoader extends AssetLoader {
  const _MenuTranslationsLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => {
    'navigation': {'menu': 'Menu'},
    'auth': {
      'logout': 'Terminar sessão',
      'logoutConfirmTitle': 'Terminar sessão?',
      'logoutConfirmMessage': 'Terá de iniciar sessão novamente.',
    },
    'common': {'cancel': 'Cancelar', 'confirm': 'Confirmar'},
    'errors': {'generic': 'Ocorreu um erro.'},
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  Future<void> pumpMenu(
    WidgetTester tester, {
    required LogoutUseCase logoutUseCase,
    required VoidCallback onLoggedOut,
  }) async {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          logoutUseCaseProvider.overrideWithValue(logoutUseCase),
        ],
        child: EasyLocalization(
          supportedLocales: const [Locale('pt')],
          path: 'unused',
          assetLoader: const _MenuTranslationsLoader(),
          fallbackLocale: const Locale('pt'),
          startLocale: const Locale('pt'),
          saveLocale: false,
          child: Builder(
            builder: (context) => MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: Scaffold(
                key: scaffoldKey,
                drawer: SessionMenuDrawer(onLoggedOut: onLoggedOut),
                body: const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    scaffoldKey.currentState!.openDrawer();
    await tester.pumpAndSettle();
  }

  testWidgets('contains only the approved logout session action', (
    tester,
  ) async {
    final logoutUseCase = _MockLogoutUseCase();

    await pumpMenu(tester, logoutUseCase: logoutUseCase, onLoggedOut: () {});

    expect(find.text('Menu'), findsOneWidget);
    expect(find.text('Terminar sessão'), findsOneWidget);
    expect(find.text('Simular Estados'), findsNothing);
  });

  testWidgets('requires confirmation before logging out', (tester) async {
    final logoutUseCase = _MockLogoutUseCase();
    var loggedOut = false;
    when(
      logoutUseCase.call,
    ).thenAnswer((_) async => const Right<Failure, Unit>(unit));
    await pumpMenu(
      tester,
      logoutUseCase: logoutUseCase,
      onLoggedOut: () => loggedOut = true,
    );

    await tester.tap(find.text('Terminar sessão'));
    await tester.pumpAndSettle();
    expect(find.text('Terminar sessão?'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    verifyNever(logoutUseCase.call);

    await tester.tap(find.text('Terminar sessão'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    verify(logoutUseCase.call).called(1);
    expect(loggedOut, isTrue);
  });
}
