import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cedsif_overtime_mobile/features/home/domain/entities/home_content.dart';
import 'package:cedsif_overtime_mobile/features/home/presentation/providers/home_provider.dart';
import 'package:cedsif_overtime_mobile/features/home/presentation/widgets/home_content_view.dart';

class _TranslationsLoader extends AssetLoader {
  const _TranslationsLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => {
    'home': {'placeholder': 'Localized home'},
    'errors': {'network': 'Localized network error'},
    'common': {'retry': 'Localized retry'},
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  Future<void> pumpView(
    WidgetTester tester,
    HomeState state, {
    VoidCallback? onRetry,
  }) async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        path: 'unused',
        assetLoader: const _TranslationsLoader(),
        fallbackLocale: const Locale('en'),
        saveLocale: false,
        child: Builder(
          builder: (context) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: Scaffold(
              body: HomeContentView(state: state, onRetry: onRetry ?? () {}),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('renders loading without user-facing text', (tester) async {
    await pumpView(tester, const HomeState(isLoading: true));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('translates content and error/retry keys', (tester) async {
    await pumpView(
      tester,
      const HomeState(content: HomeContent(translationKey: 'home.placeholder')),
    );
    expect(find.text('Localized home'), findsOneWidget);

    var retried = false;
    await pumpView(
      tester,
      const HomeState(errorKey: 'errors.network'),
      onRetry: () => retried = true,
    );
    expect(find.text('Localized network error'), findsOneWidget);
    await tester.tap(find.text('Localized retry'));
    expect(retried, isTrue);
  });
}
