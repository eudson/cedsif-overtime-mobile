import 'package:flutter_test/flutter_test.dart';

import 'package:cedsif_overtime_mobile/core/utils/currency_formatter.dart';

void main() {
  test('requires currency presentation to be supplied by the caller', () {
    expect(
      AppCurrencyFormatter.format(1234.5, locale: 'en_US', symbol: r'$'),
      r'$1,234.50',
    );
    expect(
      AppCurrencyFormatter.format(1234.5, locale: 'en_US', currencyCode: 'EUR'),
      contains('EUR'),
    );
  });
}
