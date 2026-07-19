enum AppEnvironment { development, staging, production }

abstract final class EnvironmentConfig {
  static const Duration defaultTimeout = Duration(seconds: 30);

  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _apiTimeout = String.fromEnvironment('API_TIMEOUT');
  static const String _environment = String.fromEnvironment('ENV');
  static const String firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
  );
  static const String firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
  static const String firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
  );
  static const String firebaseStorageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );
  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN');
  static const String _analytics = String.fromEnvironment('ENABLE_ANALYTICS');

  static Duration get apiTimeout => parseTimeout(_apiTimeout);
  static AppEnvironment get environment => parseEnvironment(_environment);
  static bool get enableAnalytics => parseBool(_analytics);
  static bool get isProduction => environment == AppEnvironment.production;

  static AppEnvironment parseEnvironment(String value) {
    return switch (value.trim().toLowerCase()) {
      'production' || 'prod' => AppEnvironment.production,
      'staging' || 'stage' => AppEnvironment.staging,
      _ => AppEnvironment.development,
    };
  }

  static Duration parseTimeout(String value) {
    final milliseconds = int.tryParse(value.trim());
    return milliseconds != null && milliseconds > 0
        ? Duration(milliseconds: milliseconds)
        : defaultTimeout;
  }

  static bool parseBool(String value) => value.trim().toLowerCase() == 'true';
}
