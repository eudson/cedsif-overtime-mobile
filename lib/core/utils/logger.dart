import 'package:logger/logger.dart';

import 'package:cedsif_overtime_mobile/core/utils/log_redactor.dart';

abstract interface class AppLogSink {
  void log(
    Level level,
    Object? message, {
    Object? error,
    StackTrace? stackTrace,
  });
}

final class LoggerLogSink implements AppLogSink {
  LoggerLogSink([Logger? logger]) : _logger = logger ?? Logger();

  final Logger _logger;

  @override
  void log(
    Level level,
    Object? message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.log(level, message, error: error, stackTrace: stackTrace);
  }
}

abstract final class AppLogger {
  static AppLogSink _sink = LoggerLogSink();

  static void setSink(AppLogSink sink) => _sink = sink;

  static void resetSink() => _sink = LoggerLogSink();

  static void debug(Object? message, {Object? error, StackTrace? stackTrace}) =>
      _log(Level.debug, message, error: error, stackTrace: stackTrace);

  static void info(Object? message, {Object? error, StackTrace? stackTrace}) =>
      _log(Level.info, message, error: error, stackTrace: stackTrace);

  static void warning(
    Object? message, {
    Object? error,
    StackTrace? stackTrace,
  }) => _log(Level.warning, message, error: error, stackTrace: stackTrace);

  static void error(Object? message, {Object? error, StackTrace? stackTrace}) =>
      _log(Level.error, message, error: error, stackTrace: stackTrace);

  static void _log(
    Level level,
    Object? message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final safeStackTrace = stackTrace == null
        ? null
        : StackTrace.fromString(LogRedactor.redact(stackTrace.toString()));
    _sink.log(
      level,
      LogRedactor.redactObject(message),
      error: LogRedactor.redactObject(error),
      stackTrace: safeStackTrace,
    );
  }
}
