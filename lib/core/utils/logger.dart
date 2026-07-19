import 'package:logger/logger.dart';

import 'package:cedsif_overtime_mobile/core/utils/log_redactor.dart';

abstract final class AppLogger {
  static final Logger _logger = Logger();

  static void debug(Object? message, {Object? error, StackTrace? stackTrace}) {
    _logger.d(
      LogRedactor.redactObject(message),
      error: LogRedactor.redactObject(error),
      stackTrace: stackTrace,
    );
  }

  static void info(Object? message, {Object? error, StackTrace? stackTrace}) {
    _logger.i(
      LogRedactor.redactObject(message),
      error: LogRedactor.redactObject(error),
      stackTrace: stackTrace,
    );
  }

  static void warning(
    Object? message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.w(
      LogRedactor.redactObject(message),
      error: LogRedactor.redactObject(error),
      stackTrace: stackTrace,
    );
  }

  static void error(Object? message, {Object? error, StackTrace? stackTrace}) {
    _logger.e(
      LogRedactor.redactObject(message),
      error: LogRedactor.redactObject(error),
      stackTrace: stackTrace,
    );
  }
}
