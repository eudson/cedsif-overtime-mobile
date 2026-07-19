import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:cedsif_overtime_mobile/core/utils/jwt_decoder.dart';

void main() {
  String tokenFor(Map<String, Object?> payload) {
    final encoded = base64Url
        .encode(utf8.encode(jsonEncode(payload)))
        .replaceAll('=', '');
    return 'header.$encoded.signature';
  }

  test('decodes a valid JWT payload', () {
    expect(JwtDecoder.decode(tokenFor({'sub': '123'})), {'sub': '123'});
  });

  test('returns null for malformed tokens and non-object payloads', () {
    expect(JwtDecoder.decode('not-a-jwt'), isNull);
    expect(JwtDecoder.decode('a.%%%.b'), isNull);
    expect(JwtDecoder.decode(tokenFor(const {})), isEmpty);
  });

  test('checks expiry defensively', () {
    final now = DateTime.fromMillisecondsSinceEpoch(2000 * 1000, isUtc: true);
    expect(JwtDecoder.isExpired(tokenFor({'exp': 1999}), now: now), isTrue);
    expect(JwtDecoder.isExpired(tokenFor({'exp': 2001}), now: now), isFalse);
    expect(
      JwtDecoder.isExpired(tokenFor({'exp': 'invalid'}), now: now),
      isTrue,
    );
    expect(JwtDecoder.isExpired(tokenFor({'exp': 1e100}), now: now), isTrue);
    expect(JwtDecoder.isExpired('bad', now: now), isTrue);
  });
}
