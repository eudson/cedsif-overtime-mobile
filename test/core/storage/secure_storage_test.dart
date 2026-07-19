import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cedsif_overtime_mobile/core/storage/secure_storage.dart';

class _MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late _MockFlutterSecureStorage delegate;
  late SecureStorage storage;

  setUp(() {
    delegate = _MockFlutterSecureStorage();
    storage = SecureStorage(delegate);
  });

  test('reads and writes access token using its private key', () async {
    when(
      () => delegate.write(
        key: SecureStorage.accessTokenKey,
        value: 'access-token',
      ),
    ).thenAnswer((_) async {});
    when(
      () => delegate.read(key: SecureStorage.accessTokenKey),
    ).thenAnswer((_) async => 'access-token');

    await storage.writeAccessToken('access-token');

    expect(await storage.readAccessToken(), 'access-token');
  });

  test('reads and writes refresh token using its private key', () async {
    when(
      () => delegate.write(
        key: SecureStorage.refreshTokenKey,
        value: 'refresh-token',
      ),
    ).thenAnswer((_) async {});
    when(
      () => delegate.read(key: SecureStorage.refreshTokenKey),
    ).thenAnswer((_) async => 'refresh-token');

    await storage.writeRefreshToken('refresh-token');

    expect(await storage.readRefreshToken(), 'refresh-token');
  });

  test('clearTokens deletes only the two token entries', () async {
    when(
      () => delegate.delete(key: any(named: 'key')),
    ).thenAnswer((_) async {});

    await storage.clearTokens();

    verify(() => delegate.delete(key: SecureStorage.accessTokenKey)).called(1);
    verify(() => delegate.delete(key: SecureStorage.refreshTokenKey)).called(1);
    verifyNever(() => delegate.deleteAll());
  });
}
