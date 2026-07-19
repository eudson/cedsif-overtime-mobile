import 'package:flutter_test/flutter_test.dart';

import 'package:cedsif_overtime_mobile/core/utils/date_utils.dart';

void main() {
  test('formats dates using the caller supplied locale and pattern', () {
    final date = DateTime(2026, 7, 19);
    expect(
      AppDateUtils.format(date, pattern: 'yyyy-MM-dd', locale: 'en_US'),
      '2026-07-19',
    );
  });

  test('parses valid ISO dates and rejects invalid input', () {
    expect(AppDateUtils.tryParseIso('2026-07-19')?.year, 2026);
    expect(AppDateUtils.tryParseIso('not-a-date'), isNull);
  });
}
