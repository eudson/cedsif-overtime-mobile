abstract final class LogRedactor {
  static const String redactedValue = '[REDACTED]';

  static final RegExp _bearerPattern = RegExp(
    r'\bBearer\s+[^\s,;]+',
    caseSensitive: false,
  );
  static final RegExp _emailPattern = RegExp(
    r'\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b',
    caseSensitive: false,
  );
  static final RegExp _sensitivePairPattern = RegExp(
    r'''\b(token|password|secret(?:[_-]?key)?)\s*[:=]\s*(?:["'][^"']*["']|[^\s,;}]+)''',
    caseSensitive: false,
  );
  static final RegExp _sensitiveKeyPattern = RegExp(
    r'(token|password|secret(?:[_-]?key)?)',
    caseSensitive: false,
  );

  static String redact(String value) => value
      .replaceAllMapped(_bearerPattern, (_) => 'Bearer $redactedValue')
      .replaceAll(_emailPattern, redactedValue)
      .replaceAllMapped(
        _sensitivePairPattern,
        (match) => '${match.group(1)}=$redactedValue',
      );

  static Object? redactObject(Object? value) {
    return switch (value) {
      String() => redact(value),
      Map() => <Object?, Object?>{
        for (final entry in value.entries)
          entry.key: _isSensitiveKey(entry.key)
              ? redactedValue
              : redactObject(entry.value),
      },
      Iterable() => value.map(redactObject).toList(growable: false),
      num() || bool() || null => value,
      _ => redact(value.toString()),
    };
  }

  static bool _isSensitiveKey(Object? key) =>
      key is String && _sensitiveKeyPattern.hasMatch(key);
}
