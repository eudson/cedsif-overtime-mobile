import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cedsif_overtime_mobile/core/utils/analytics_service.dart';

class _MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

void main() {
  test('delegates events when analytics is enabled and available', () async {
    final analytics = _MockFirebaseAnalytics();
    when(
      () => analytics.logEvent(
        name: any(named: 'name'),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((_) async {});
    final service = AnalyticsService(analytics: analytics, enabled: true);

    await service.logEvent(name: 'opened', parameters: {'source': 'home'});

    verify(
      () => analytics.logEvent(name: 'opened', parameters: {'source': 'home'}),
    ).called(1);
  });

  test('is a no-op when disabled or unavailable', () async {
    final analytics = _MockFirebaseAnalytics();
    final disabled = AnalyticsService(analytics: analytics, enabled: false);
    const unavailable = AnalyticsService(enabled: true);

    await disabled.logEvent(name: 'ignored');
    await unavailable.logEvent(name: 'ignored');

    verifyNever(
      () => analytics.logEvent(
        name: any(named: 'name'),
        parameters: any(named: 'parameters'),
      ),
    );
  });

  test('does not let analytics failures escape bootstrap boundaries', () async {
    final analytics = _MockFirebaseAnalytics();
    when(
      () => analytics.logEvent(
        name: any(named: 'name'),
        parameters: any(named: 'parameters'),
      ),
    ).thenThrow(StateError('unavailable'));
    final service = AnalyticsService(analytics: analytics, enabled: true);

    await expectLater(service.logEvent(name: 'opened'), completes);
  });
}
