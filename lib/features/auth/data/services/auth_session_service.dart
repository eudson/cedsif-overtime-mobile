import 'package:cedsif_overtime_mobile/core/storage/secure_storage.dart';
import 'package:cedsif_overtime_mobile/core/utils/jwt_decoder.dart';

typedef SessionClock = DateTime Function();

class AuthSessionService {
  AuthSessionService(this._secureStorage, {SessionClock? now})
    : _now = now ?? DateTime.now;

  final SecureStorage _secureStorage;
  final SessionClock _now;

  Future<bool> hasValidSession() async {
    try {
      final accessToken = await _secureStorage.readAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        return false;
      }
      if (!JwtDecoder.isExpired(accessToken, now: _now())) {
        return true;
      }
      await _clearExpiredSession();
      return false;
    } on Object {
      return false;
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
