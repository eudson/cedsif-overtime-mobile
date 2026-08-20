import 'package:cedsif_overtime_mobile/core/storage/secure_storage.dart';
import 'package:cedsif_overtime_mobile/core/utils/jwt_decoder.dart';

typedef SessionClock = DateTime Function();

class AuthSessionService {
  AuthSessionService(this._secureStorage, {SessionClock? now})
    : _now = now ?? DateTime.now;

  final SecureStorage _secureStorage;
  final SessionClock _now;

  Future<DateTime?> validUntil() async {
    final String? accessToken;
    try {
      accessToken = await _secureStorage.readAccessToken();
    } on Object {
      return null;
    }

    final expiry = _expiryOf(accessToken);
    if (expiry != null && expiry.isAfter(_now().toUtc())) {
      return expiry;
    }
    await _clearExpiredSession();
    return null;
  }

  Future<bool> hasValidSession() async => await validUntil() != null;

  DateTime? _expiryOf(String? accessToken) {
    if (accessToken == null || accessToken.isEmpty) {
      return null;
    }
    final expiry = JwtDecoder.decode(accessToken)?['exp'];
    if (expiry is! num || !expiry.isFinite || expiry < 0) {
      return null;
    }
    try {
      return DateTime.fromMillisecondsSinceEpoch(
        (expiry * Duration.millisecondsPerSecond).round(),
        isUtc: true,
      );
    } on RangeError {
      return null;
    }
  }

  Future<void> _clearExpiredSession() async {
    try {
      await _secureStorage.clearTokens();
    } on Object {
      // Session validation remains fail-closed when cleanup is unavailable.
    }
  }
}
