import 'package:flutter_test/flutter_test.dart';

import 'package:cedsif_overtime_mobile/features/overtime/domain/entities/overtime_session.dart';

void main() {
  final startedAt = DateTime(2026, 8, 14, 8);

  test('reviewing freezes elapsed time at the pause instant', () {
    final session = OvertimeSession(
      id: 'session',
      startedAt: startedAt,
      status: OvertimeSessionStatus.active,
    );

    final reviewing = session.pauseAt(DateTime(2026, 8, 14, 9));

    expect(reviewing.status, OvertimeSessionStatus.reviewing);
    expect(reviewing.endedAt, DateTime(2026, 8, 14, 9));
    expect(
      reviewing.durationAt(DateTime(2026, 8, 14, 10)),
      const Duration(hours: 1),
    );
  });

  test('resuming excludes review time from the registered duration', () {
    final reviewing = OvertimeSession(
      id: 'session',
      startedAt: startedAt,
      endedAt: DateTime(2026, 8, 14, 9),
      status: OvertimeSessionStatus.reviewing,
    );

    final resumed = reviewing.resumeAt(DateTime(2026, 8, 14, 9, 30));

    expect(resumed.status, OvertimeSessionStatus.active);
    expect(resumed.endedAt, isNull);
    expect(resumed.pausedDuration, const Duration(minutes: 30));
    expect(
      resumed.durationAt(DateTime(2026, 8, 14, 10)),
      const Duration(hours: 1, minutes: 30),
    );
  });

  test('multiple review cycles are all excluded before submission', () {
    final session = OvertimeSession(
      id: 'session',
      startedAt: startedAt,
      status: OvertimeSessionStatus.active,
    );

    final submitted = session
        .pauseAt(DateTime(2026, 8, 14, 9))
        .resumeAt(DateTime(2026, 8, 14, 9, 15))
        .pauseAt(DateTime(2026, 8, 14, 10))
        .submit();

    expect(submitted.status, OvertimeSessionStatus.pending);
    expect(submitted.pausedDuration, const Duration(minutes: 15));
    expect(
      submitted.durationAt(DateTime(2026, 8, 14, 12)),
      const Duration(hours: 1, minutes: 45),
    );
  });
}
