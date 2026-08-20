import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all supported locales expose the Portuguese fallback keys', () {
    final portuguese = _scalarKeys(_load('pt'));

    for (final locale in ['en', 'es']) {
      expect(
        _scalarKeys(_load(locale)),
        containsAll(portuguese),
        reason: '$locale must translate every supported application key',
      );
    }
  });
}

Map<String, dynamic> _load(String locale) =>
    jsonDecode(File('assets/translations/$locale.json').readAsStringSync())
        as Map<String, dynamic>;

Set<String> _scalarKeys(Map<String, dynamic> source, [String prefix = '']) {
  final keys = <String>{};
  for (final entry in source.entries) {
    final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
    if (entry.value case final Map<String, dynamic> nested) {
      keys.addAll(_scalarKeys(nested, key));
    } else {
      keys.add(key);
    }
  }
  return keys;
}
