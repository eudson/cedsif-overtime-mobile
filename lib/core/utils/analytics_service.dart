import 'package:firebase_analytics/firebase_analytics.dart';

final class AnalyticsService {
  AnalyticsService({FirebaseAnalytics? analytics, required this.enabled})
    : _analytics = analytics;

  final bool enabled;
  FirebaseAnalytics? _analytics;

  void attach(FirebaseAnalytics analytics) {
    if (enabled) {
      _analytics = analytics;
    }
  }

  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    final client = _analytics;
    if (!enabled || client == null) return;

    try {
      await client.logEvent(name: name, parameters: parameters);
    } on Object {
      // Analytics is non-critical and must never prevent application startup.
    }
  }
}
