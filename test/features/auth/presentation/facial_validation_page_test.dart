import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:cedsif_overtime_mobile/core/config/environment_config.dart';
import 'package:cedsif_overtime_mobile/core/constants/constants.dart';
import 'package:cedsif_overtime_mobile/features/auth/presentation/pages/facial_validation_page.dart';
import 'package:cedsif_overtime_mobile/features/auth/presentation/providers/login_provider.dart';
import 'package:cedsif_overtime_mobile/features/auth/presentation/services/facial_camera.dart';
import 'package:cedsif_overtime_mobile/features/auth/presentation/services/facial_verifier.dart';
import 'package:cedsif_overtime_mobile/widgets/app_button.dart';

class _FakeFacialCamera implements FacialCamera {
  int initializeCalls = 0;
  int captureCalls = 0;
  int disposeCalls = 0;
  int deleteCalls = 0;
  Object? initializeError;

  @override
  Future<void> initialize() async {
    initializeCalls += 1;
    final error = initializeError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Widget buildPreview() =>
      const ColoredBox(key: Key('camera-preview'), color: Colors.black);

  @override
  Future<CapturedFace> capture() async {
    captureCalls += 1;
    return CapturedFace(
      path: '/tmp/face.jpg',
      delete: () async => deleteCalls += 1,
    );
  }

  @override
  Future<void> dispose() async => disposeCalls += 1;
}

class _FakeFacialVerifier implements FacialVerifier {
  int verifyCalls = 0;

  @override
  Future<String> verify(CapturedFace face) async {
    verifyCalls += 1;
    return 'SIMULATED-verification-1';
  }
}

void main() {
  test('enables facial simulation only for development', () {
    expect(
      FacialSimulationPolicy.isEnabled(AppEnvironment.development),
      isTrue,
    );
    expect(FacialSimulationPolicy.isEnabled(AppEnvironment.staging), isFalse);
    expect(
      FacialSimulationPolicy.isEnabled(AppEnvironment.production),
      isFalse,
    );
  });

  testWidgets(
    'captures, simulates verification, deletes image, and continues',
    (tester) async {
      final camera = _FakeFacialCamera();
      final verifier = _FakeFacialVerifier();
      String? reference;
      await tester.pumpWidget(
        MaterialApp(
          home: FacialValidationPage(
            camera: camera,
            verifier: verifier,
            simulationEnabled: true,
            onValidated: (value) => reference = value,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('camera-preview')), findsOneWidget);
      expect(find.byType(AppButton), findsOneWidget);

      await tester.ensureVisible(find.byType(AppButton));
      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      expect(camera.captureCalls, 1);
      expect(verifier.verifyCalls, 1);
      expect(camera.deleteCalls, 1);
      expect(reference, 'SIMULATED-verification-1');
    },
  );

  testWidgets('stores the reference before opening Home', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final router = GoRouter(
      initialLocation: RouteConstants.facialValidation,
      routes: [
        GoRoute(
          path: RouteConstants.facialValidation,
          builder: (context, state) => FacialValidationPage(
            camera: _FakeFacialCamera(),
            verifier: _FakeFacialVerifier(),
            simulationEnabled: true,
          ),
        ),
        GoRoute(
          path: RouteConstants.home,
          builder: (context, state) =>
              const Scaffold(body: SizedBox(key: Key('home-destination'))),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byType(AppButton));
    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();

    expect(container.read(facialReferenceProvider), 'SIMULATED-verification-1');
    expect(find.byKey(const Key('home-destination')), findsOneWidget);
  });

  testWidgets('fails closed without initializing camera outside development', (
    tester,
  ) async {
    final camera = _FakeFacialCamera();
    await tester.pumpWidget(
      MaterialApp(
        home: FacialValidationPage(
          camera: camera,
          verifier: _FakeFacialVerifier(),
          simulationEnabled: false,
          onValidated: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(camera.initializeCalls, 0);
    expect(find.byType(AppButton), findsNothing);
    expect(find.text('auth.verificationUnavailable'), findsOneWidget);
  });

  testWidgets('shows a retry action when camera initialization fails', (
    tester,
  ) async {
    final camera = _FakeFacialCamera()
      ..initializeError = StateError('permission denied');
    await tester.pumpWidget(
      MaterialApp(
        home: FacialValidationPage(
          camera: camera,
          verifier: _FakeFacialVerifier(),
          simulationEnabled: true,
          onValidated: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('auth.cameraUnavailable'), findsOneWidget);
    expect(find.text('common.retry'), findsOneWidget);

    camera.initializeError = null;
    await tester.tap(find.text('common.retry'));
    await tester.pumpAndSettle();

    expect(camera.initializeCalls, 2);
    expect(find.byKey(const Key('camera-preview')), findsOneWidget);
  });
}
