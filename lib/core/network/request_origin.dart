import 'package:dio/dio.dart';

abstract final class RequestOrigin {
  static bool isAllowed(RequestOptions options, String apiBaseUrl) =>
      isAllowedPath(options.path, apiBaseUrl);

  static bool isAllowedPath(String path, String apiBaseUrl) {
    final target = Uri.tryParse(path);
    if (target == null || path.startsWith('//')) {
      return false;
    }
    if (!target.hasScheme) {
      return true;
    }

    final base = Uri.tryParse(apiBaseUrl);
    return base != null &&
        base.hasScheme &&
        target.scheme.toLowerCase() == base.scheme.toLowerCase() &&
        target.host.toLowerCase() == base.host.toLowerCase() &&
        target.port == base.port;
  }
}
