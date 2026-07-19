import 'package:flutter_test/flutter_test.dart';

import 'package:cedsif_overtime_mobile/core/utils/log_redactor.dart';

void main() {
  test('redacts bearer tokens and email addresses', () {
    final value = LogRedactor.redact(
      'Authorization: Bearer abc.def.ghi for person@example.com',
    );

    expect(value, isNot(contains('abc.def.ghi')));
    expect(value, isNot(contains('person@example.com')));
    expect(value, contains(LogRedactor.redactedValue));
  });

  test('redacts sensitive key values in maps recursively', () {
    final value =
        LogRedactor.redactObject({
              'token': 'token-value',
              'nested': {
                'password': 'password-value',
                'secretKey': 'secret-value',
              },
              'safe': 'visible',
            })
            as Map<Object?, Object?>;

    expect(value['token'], LogRedactor.redactedValue);
    expect(
      (value['nested']! as Map<Object?, Object?>)['password'],
      LogRedactor.redactedValue,
    );
    expect(
      (value['nested']! as Map<Object?, Object?>)['secretKey'],
      LogRedactor.redactedValue,
    );
    expect(value['safe'], 'visible');
  });

  test('redacts identity and session-like map fields', () {
    final value = LogRedactor.redactObject({
      'authorization': 'raw-auth',
      'apiKey': 'raw-api-key',
      'cookie': 'raw-cookie',
      'session': 'raw-session',
      'phone': 'raw-phone',
      'address': 'raw-address',
      'fullName': 'raw-name',
    }).toString();

    for (final secret in [
      'raw-auth',
      'raw-api-key',
      'raw-cookie',
      'raw-session',
      'raw-phone',
      'raw-address',
      'raw-name',
    ]) {
      expect(value, isNot(contains(secret)));
    }
  });

  test('redacts sensitive key-value pairs in text', () {
    final value = LogRedactor.redact(
      'password=hunter2 secret: private token="abc"',
    );
    expect(value, isNot(contains('hunter2')));
    expect(value, isNot(contains('private')));
    expect(value, isNot(contains('abc')));
  });

  test('redacts the string representation of error objects', () {
    final value = LogRedactor.redactObject(StateError('token=private-value'));
    expect(value, isA<String>());
    expect(value, isNot(contains('private-value')));
    expect(value, contains(LogRedactor.redactedValue));
  });
}
