import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cedsif_overtime_mobile/core/storage/secure_storage.dart';
import 'package:cedsif_overtime_mobile/features/auth/data/services/auth_session_service.dart';

class _MockSecureStorage extends Mock implements SecureStorage {}

void main() {
  String tokenExpiringAt(int secondsSinceEpoch) {
    final payload = base64Url
        .encode(
          utf8.encode(jsonEncode(<String, Object?>{'exp': secondsSinceEpoch})),
        )
        .replaceAll('=', '');
    return 'header.$payload.signature';
  }

  late _MockSecureStorage storage;
  final now = DateTime.fromMillisecondsSinceEpoch(2000 * 1000, isUtc: true);

  setUp(() {
    storage = _MockSecureStorage();
  });

  test(
    'accepts an unexpired cached JWT without any network dependency',
    () async {
      when(
        storage.readAccessToken,
      ).thenAnswer((_) async => tokenExpiringAt(2001));
      final service = AuthSessionService(storage, now: () => now);

      expect(await service.hasValidSession(), isTrue);

      verifyNever(storage.clearTokens);
    },
  );

  test('clears an expired cached session and requires online login', () async {
    when(
      storage.readAccessToken,
    ).thenAnswer((_) async => tokenExpiringAt(2000));
    when(storage.clearTokens).thenAnswer((_) async {});
    final service = AuthSessionService(storage, now: () => now);

    expect(await service.hasValidSession(), isFalse);

    verify(storage.clearTokens).called(1);
  });

  test('fails closed when the cached token is missing or malformed', () async {
    when(storage.readAccessToken).thenAnswer((_) async => 'malformed');
    when(storage.clearTokens).thenAnswer((_) async {});
    final service = AuthSessionService(storage, now: () => now);

    expect(await service.hasValidSession(), isFalse);

    verify(storage.clearTokens).called(1);
  });

  test('fails closed when secure storage cannot be read', () async {
    when(storage.readAccessToken).thenThrow(StateError('unavailable'));
    final service = AuthSessionService(storage, now: () => now);

    expect(await service.hasValidSession(), isFalse);
  });
}
