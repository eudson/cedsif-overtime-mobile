import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

import 'package:cedsif_overtime_mobile/core/utils/logger.dart';

class _RecordingSink implements AppLogSink {
  final records =
      <({Object? message, Object? error, StackTrace? stackTrace})>[];

  @override
  void log(
    Level level,
    Object? message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    records.add((message: message, error: error, stackTrace: stackTrace));
  }
}

void main() {
  tearDown(AppLogger.resetSink);

  test('redacts message, error, and stack trace before invoking sink', () {
    final sink = _RecordingSink();
    AppLogger.setSink(sink);

    AppLogger.error(
      'authorization=Bearer raw-token person@example.com',
      error: StateError('password=raw-password'),
      stackTrace: StackTrace.fromString('cookie=raw-cookie'),
    );

    final record = sink.records.single;
    final received = '${record.message} ${record.error} ${record.stackTrace}';
    expect(received, isNot(contains('raw-token')));
    expect(received, isNot(contains('person@example.com')));
    expect(received, isNot(contains('raw-password')));
    expect(received, isNot(contains('raw-cookie')));
  });

  test('never sends compound token values to the sink', () {
    final sink = _RecordingSink();
    AppLogger.setSink(sink);

    AppLogger.info({
      'accessToken': 'raw-access-token',
      'nested': {'refresh_token': 'raw-refresh-token'},
    });

    final received = sink.records.single.message.toString();
    expect(received, isNot(contains('raw-access-token')));
    expect(received, isNot(contains('raw-refresh-token')));
  });
}
