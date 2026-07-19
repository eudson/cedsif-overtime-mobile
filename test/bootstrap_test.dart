import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cedsif_overtime_mobile/bootstrap.dart';
import 'package:cedsif_overtime_mobile/core/utils/analytics_service.dart';

class _MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

void main() {
  test('non-critical initialization failures degrade gracefully', () async {
    final result = await runNonCriticalStep<int>(
      'test.step',
      () async => throw StateError('token=private-value'),
    );

    expect(result, isNull);
  });

  test('Sentry is enabled only outside debug with a configured DSN', () {
    expect(shouldEnableSentry(isDebug: false, dsn: 'https://dsn'), isTrue);
    expect(shouldEnableSentry(isDebug: true, dsn: 'https://dsn'), isFalse);
    expect(shouldEnableSentry(isDebug: false, dsn: ''), isFalse);
  });

  test('fatal reporting redacts errors before external capture', () async {
    Object? capturedError;
    StackTrace? capturedStack;

    await reportFatalError(
      StateError('token=private-value'),
      StackTrace.fromString('email=person@example.com'),
      sentryEnabled: true,
      captureException: (error, stackTrace) async {
        capturedError = error;
        capturedStack = stackTrace;
      },
    );

    expect(capturedError.toString(), isNot(contains('private-value')));
    expect(capturedStack.toString(), isNot(contains('person@example.com')));
  });

  test('app runner is invoked without waiting for Firebase', () async {
    final firebase = Completer<void>();
    final analytics = _MockFirebaseAnalytics();
    when(
      () => analytics.logEvent(
        name: any(named: 'name'),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((_) async {});
    final service = AnalyticsService(enabled: true);
    var appRan = false;
    var initializationFinished = false;

    final initialization = initializeFirebaseAfterApp(
      appRunner: () => appRan = true,
      initializeFirebase: () => firebase.future,
      analyticsFactory: () => analytics,
      analyticsService: service,
    )..whenComplete(() => initializationFinished = true);

    expect(appRan, isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(initializationFinished, isFalse);

    firebase.complete();
    await initialization;
    await service.logEvent(name: 'ready');
    verify(() => analytics.logEvent(name: 'ready')).called(1);
  });

  test(
    'app runner is invoked without waiting for background services',
    () async {
      final backgroundServices = Completer<void>();
      var appRan = false;

      final initialization = initializeBackgroundServicesAfterApp(
        appRunner: () => appRan = true,
        initializeBackgroundServices: () => backgroundServices.future,
      );

      expect(appRan, isTrue);
      backgroundServices.complete();
      await initialization;
    },
  );

  testWidgets('fallback root renders without localization', (tester) async {
    await tester.pumpWidget(buildBootstrapFallbackRoot());

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  test('Firebase failure leaves the running app and analytics safe', () async {
    final service = AnalyticsService(enabled: true);
    var appRan = false;

    await initializeFirebaseAfterApp(
      appRunner: () => appRan = true,
      initializeFirebase: () async => throw StateError('unavailable'),
      analyticsFactory: () => _MockFirebaseAnalytics(),
      analyticsService: service,
    );

    expect(appRan, isTrue);
    await expectLater(service.logEvent(name: 'safe-no-op'), completes);
  });

  test(
    'Sentry readiness is published as soon as initialization succeeds',
    () async {
      final status = BootstrapStatus();

      await initializeSentryStatus(
        status,
        enabled: true,
        initializer: () async {},
      );

      expect(status.sentryReady, isTrue);
    },
  );
}
