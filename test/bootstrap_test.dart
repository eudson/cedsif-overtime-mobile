import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

import 'package:cedsif_overtime_mobile/bootstrap.dart';
import 'package:cedsif_overtime_mobile/core/utils/logger.dart';

class _RecordingSink implements AppLogSink {
  Object? error;
  StackTrace? stackTrace;

  @override
  void log(
    Level level,
    Object? message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    this.error = error;
    this.stackTrace = stackTrace;
  }
}

void main() {
  tearDown(AppLogger.resetSink);

  test('non-critical initialization failures degrade gracefully', () async {
    final result = await runNonCriticalStep<int>(
      'test.step',
      () async => throw StateError('token=private-value'),
    );

    expect(result, isNull);
  });

  test('fatal reporting redacts errors before local logging', () async {
    final sink = _RecordingSink();
    AppLogger.setSink(sink);

    await reportFatalError(
      StateError('token=private-value'),
      StackTrace.fromString('email=person@example.com'),
    );

    expect(sink.error.toString(), isNot(contains('private-value')));
    expect(sink.stackTrace.toString(), isNot(contains('person@example.com')));
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
}
