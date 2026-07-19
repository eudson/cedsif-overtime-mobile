import 'package:intl/intl.dart';

abstract final class AppCurrencyFormatter {
  static String format(
    num value, {
    required String locale,
    String? symbol,
    String? currencyCode,
    int decimalDigits = 2,
  }) {
    if (symbol == null && currencyCode == null) {
      throw ArgumentError('Provide a symbol or currencyCode.');
    }
    return NumberFormat.currency(
      locale: locale,
      symbol: symbol,
      name: currencyCode,
      decimalDigits: decimalDigits,
    ).format(value);
  }
}
