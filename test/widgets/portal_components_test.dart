import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cedsif_overtime_mobile/theme/app_spacing.dart';
import 'package:cedsif_overtime_mobile/theme/app_theme.dart';
import 'package:cedsif_overtime_mobile/widgets/app_button.dart';
import 'package:cedsif_overtime_mobile/widgets/app_scaffold.dart';
import 'package:cedsif_overtime_mobile/widgets/app_text_field.dart';
import 'package:cedsif_overtime_mobile/widgets/info_card.dart';
import 'package:cedsif_overtime_mobile/widgets/semantic_banner.dart';
import 'package:cedsif_overtime_mobile/widgets/status_chip.dart';

class _ComponentTranslationsLoader extends AssetLoader {
  const _ComponentTranslationsLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => {
    'app': {
      'title': 'Portal do FAE',
      'emblem': 'Emblema da República de Moçambique',
    },
    'navigation': {
      'home': 'Início',
      'history': 'Histórico',
      'profile': 'Perfil',
      'menu': 'Menu',
    },
    'status': {
      'inProgress': 'Em curso',
      'approved': 'Aprovada',
      'pending': 'Pendente',
      'blocked': 'Bloqueado',
      'offline': 'Offline',
    },
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  Future<void> pumpComponent(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('pt')],
        path: 'unused',
        assetLoader: const _ComponentTranslationsLoader(),
        fallbackLocale: const Locale('pt'),
        startLocale: const Locale('pt'),
        saveLocale: false,
        child: Builder(
          builder: (context) => MaterialApp(
            theme: AppTheme.light,
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: Scaffold(
              body: Center(child: SizedBox(width: 320, child: child)),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('AppButton supports variants, icons, loading, and 56px height', (
    tester,
  ) async {
    var presses = 0;
    await pumpComponent(
      tester,
      AppButton(
        label: 'Eliminar',
        variant: AppButtonVariant.destructive,
        leadingIcon: Icons.stop_circle_outlined,
        onPressed: () => presses++,
      ),
    );

    expect(find.byIcon(Icons.stop_circle_outlined), findsOneWidget);
    expect(
      tester.getSize(find.byType(FilledButton)).height,
      AppSpacing.buttonHeight,
    );
    await tester.tap(find.text('Eliminar'));
    expect(presses, 1);

    await pumpComponent(
      tester,
      AppButton(label: 'Eliminar', isLoading: true, onPressed: () => presses++),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(AppButton));
    expect(presses, 1);
  });

  testWidgets('AppTextField renders its external label and error state', (
    tester,
  ) async {
    await pumpComponent(
      tester,
      const AppTextField(
        label: 'NUIT',
        isRequired: true,
        errorText: 'Campo obrigatório',
      ),
    );

    expect(find.text('NUIT'), findsOneWidget);
    expect(find.text('*'), findsOneWidget);
    expect(find.text('Campo obrigatório'), findsOneWidget);
    expect(
      tester.getSize(find.byType(TextFormField)).height,
      greaterThanOrEqualTo(AppSpacing.touchTarget),
    );
  });

  testWidgets('InfoCard exposes its label, value, and icons', (tester) async {
    await pumpComponent(
      tester,
      const InfoCard(
        label: 'Este mês',
        value: '18:30',
        leadingIcon: Icons.my_location_rounded,
        trailingIcon: Icons.check_circle_outline_rounded,
      ),
    );

    expect(find.text('Este mês'), findsOneWidget);
    expect(find.text('18:30'), findsOneWidget);
    expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
  });

  testWidgets('StatusChip maps every supported status to copy and icon', (
    tester,
  ) async {
    await pumpComponent(
      tester,
      const Wrap(
        children: [
          StatusChip(status: AppStatus.emCurso),
          StatusChip(status: AppStatus.aprovada),
          StatusChip(status: AppStatus.pendente),
          StatusChip(status: AppStatus.bloqueado),
          StatusChip(status: AppStatus.offline),
        ],
      ),
    );

    expect(find.text('Em curso'), findsOneWidget);
    expect(find.text('Aprovada'), findsOneWidget);
    expect(find.text('Pendente'), findsOneWidget);
    expect(find.text('Bloqueado'), findsOneWidget);
    expect(find.text('Offline'), findsOneWidget);
    expect(find.byIcon(Icons.hourglass_top_rounded), findsOneWidget);
    expect(find.byIcon(Icons.block_rounded), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
  });

  testWidgets('SemanticBanner announces its icon and message', (tester) async {
    await pumpComponent(
      tester,
      const SemanticBanner(
        kind: SemanticBannerKind.warning,
        message: 'Atenção — ação recomendada',
      ),
    );

    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    expect(find.text('Atenção — ação recomendada'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Atenção — ação recomendada'),
      findsAtLeastNWidgets(1),
    );
  });

  testWidgets('AppScaffold renders the shared header and bottom navigation', (
    tester,
  ) async {
    var menuPressed = false;
    int? selectedIndex;
    await pumpComponent(
      tester,
      AppScaffold(
        showTopBar: true,
        showBottomNavigation: true,
        onMenuPressed: () => menuPressed = true,
        onDestinationSelected: (index) => selectedIndex = index,
        body: const Text('Conteúdo'),
      ),
    );

    expect(find.text('Portal do FAE'), findsOneWidget);
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.text('Início'), findsOneWidget);
    expect(find.text('Histórico'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
    expect(
      tester.getSize(find.byTooltip('Menu')).height,
      greaterThanOrEqualTo(AppSpacing.touchTarget),
    );

    await tester.tap(find.byTooltip('Menu'));
    expect(menuPressed, isTrue);
    await tester.tap(find.text('Histórico'));
    expect(selectedIndex, 1);
  });
}
