import 'package:cedsif_overtime_mobile/core/constants/constants.dart';

enum AppEnvironment { development, staging, production }

abstract final class EnvironmentConfig {
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _apiTimeout = String.fromEnvironment('API_TIMEOUT');
  static const String _environment = String.fromEnvironment('ENV');

  static Duration get apiTimeout => parseTimeout(_apiTimeout);
  static AppEnvironment get environment => parseEnvironment(_environment);
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
        : AppConstants.defaultApiTimeout;
  }
}
