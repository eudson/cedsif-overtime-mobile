import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cedsif_overtime_mobile/core/auth/authenticated_subject.dart';
import 'package:cedsif_overtime_mobile/core/storage/secure_storage.dart';

class _MockSecureStorage extends Mock implements SecureStorage {}

void main() {
  test(
    'reads the authenticated employee subject from the access token',
    () async {
      final storage = _MockSecureStorage();
      when(
        storage.readAccessToken,
      ).thenAnswer((_) async => _token(<String, Object?>{'sub': 'employee-1'}));

      expect(await AuthenticatedSubject.read(storage), 'employee-1');
    },
  );

  test('fails closed when the token subject is unavailable', () async {
    final storage = _MockSecureStorage();
    when(storage.readAccessToken).thenThrow(StateError('unavailable'));

    expect(await AuthenticatedSubject.read(storage), isNull);
  });
}

String _token(Map<String, Object?> payload) {
  final encoded = base64Url.encode(utf8.encode(jsonEncode(payload)));
  return 'header.$encoded.signature';
}
