import 'package:intl/intl.dart';

abstract final class AppDateUtils {
  static String format(
    DateTime value, {
    required String pattern,
    required String locale,
  }) => DateFormat(pattern, locale).format(value);

  static DateTime? tryParseIso(String value) => DateTime.tryParse(value);
}
