import 'dart:convert';

abstract final class JwtDecoder {
  static Map<String, dynamic>? decode(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3 || parts[1].isEmpty) return null;
      final normalized = base64Url.normalize(parts[1]);
      final decoded = jsonDecode(utf8.decode(base64Url.decode(normalized)));
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    } on ArgumentError {
      return null;
    }
  }

  static bool isExpired(String token, {DateTime? now}) {
    final expiry = decode(token)?['exp'];
    if (expiry is! num || !expiry.isFinite || expiry < 0) return true;
    try {
      final instant = DateTime.fromMillisecondsSinceEpoch(
        (expiry * Duration.millisecondsPerSecond).round(),
        isUtc: true,
      );
      return !instant.isAfter((now ?? DateTime.now()).toUtc());
    } on RangeError {
      return true;
    }
  }
}
