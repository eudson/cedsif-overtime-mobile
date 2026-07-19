import 'package:dio/dio.dart';

abstract final class RequestOrigin {
  static bool isAllowed(RequestOptions options, String apiBaseUrl) {
    if (options.path.startsWith('//')) {
      return false;
    }
    final effectiveUri = options.uri;
    if (!effectiveUri.hasScheme) {
      return !Uri.parse(options.path).hasScheme;
    }
    return _hasSameOrigin(effectiveUri, Uri.tryParse(apiBaseUrl));
  }

  static bool isAllowedPath(String path, String apiBaseUrl) {
    final target = Uri.tryParse(path);
    if (target == null || path.startsWith('//')) {
      return false;
    }
    if (!target.hasScheme) {
      return true;
    }

    return _hasSameOrigin(target, Uri.tryParse(apiBaseUrl));
  }

  static bool _hasSameOrigin(Uri target, Uri? base) =>
      base != null &&
      base.hasScheme &&
      target.scheme.toLowerCase() == base.scheme.toLowerCase() &&
      target.host.toLowerCase() == base.host.toLowerCase() &&
      target.port == base.port;
}
