abstract final class AppConstants {
  static const double spacingSmall = 8;
  static const double spacingMedium = 16;
  static const double spacingLarge = 24;
  static const double borderRadius = 12;
  static const double buttonHeight = 48;
  static const double iconSizeLarge = 48;

  static const int cacheVersion = 1;
  static const int maxNetworkRetries = 1;
  static const Duration splashDuration = Duration(milliseconds: 500);
}

abstract final class RouteConstants {
  static const String splash = '/';
  static const String home = '/home';
}
