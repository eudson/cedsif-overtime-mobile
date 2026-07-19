import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  const SecureStorage([this._storage = const FlutterSecureStorage()]);

  static const accessTokenKey = 'access_token';
  static const refreshTokenKey = 'refresh_token';

  final FlutterSecureStorage _storage;

  Future<String?> readAccessToken() => _storage.read(key: accessTokenKey);

  Future<void> writeAccessToken(String token) =>
      _storage.write(key: accessTokenKey, value: token);

  Future<String?> readRefreshToken() => _storage.read(key: refreshTokenKey);

  Future<void> writeRefreshToken(String token) =>
      _storage.write(key: refreshTokenKey, value: token);

  Future<void> writeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait(<Future<void>>[
      writeAccessToken(accessToken),
      writeRefreshToken(refreshToken),
    ]);
  }

  Future<void> clearTokens() async {
    await Future.wait(<Future<void>>[
      _storage.delete(key: accessTokenKey),
      _storage.delete(key: refreshTokenKey),
    ]);
  }
}
