import 'package:firebase_analytics/firebase_analytics.dart';

final class AnalyticsService {
  const AnalyticsService({this.analytics, required this.enabled});

  final FirebaseAnalytics? analytics;
  final bool enabled;

  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    final client = analytics;
    if (!enabled || client == null) return;

    try {
      await client.logEvent(name: name, parameters: parameters);
    } on Object {
      // Analytics is non-critical and must never prevent application startup.
    }
  }
}
