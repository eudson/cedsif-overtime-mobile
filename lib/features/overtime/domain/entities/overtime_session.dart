import 'package:equatable/equatable.dart';

enum OvertimeSessionStatus { active, reviewing, pending, approved }

class OvertimeSession extends Equatable {
  const OvertimeSession({
    required this.id,
    required this.startedAt,
    required this.status,
    this.endedAt,
    this.pausedDuration = Duration.zero,
    this.startIdempotencyKey,
    this.endIdempotencyKey,
    this.submitIdempotencyKey,
  });

  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final OvertimeSessionStatus status;
  final Duration pausedDuration;
  final String? startIdempotencyKey;
  final String? endIdempotencyKey;
  final String? submitIdempotencyKey;

  Duration durationAt(DateTime now) {
    final grossDuration = (endedAt ?? now).difference(startedAt);
    final registeredDuration = grossDuration - pausedDuration;
    return registeredDuration.isNegative ? Duration.zero : registeredDuration;
  }

  OvertimeSession pauseAt(DateTime end) {
    if (status != OvertimeSessionStatus.active) {
      throw StateError('Only an active overtime session can be paused.');
    }
    return OvertimeSession(
      id: id,
      startedAt: startedAt,
      endedAt: end,
      status: OvertimeSessionStatus.reviewing,
      pausedDuration: pausedDuration,
      startIdempotencyKey: startIdempotencyKey,
      endIdempotencyKey: endIdempotencyKey,
      submitIdempotencyKey: submitIdempotencyKey,
    );
  }

  OvertimeSession resumeAt(DateTime resumedAt) {
    if (status != OvertimeSessionStatus.reviewing || endedAt == null) {
      throw StateError('Only a reviewing overtime session can be resumed.');
    }
    final reviewStartedAt = endedAt;
    final reviewDuration = resumedAt.difference(reviewStartedAt!);
    return OvertimeSession(
      id: id,
      startedAt: startedAt,
      status: OvertimeSessionStatus.active,
      pausedDuration:
          pausedDuration +
          (reviewDuration.isNegative ? Duration.zero : reviewDuration),
      startIdempotencyKey: startIdempotencyKey,
      endIdempotencyKey: endIdempotencyKey,
      submitIdempotencyKey: submitIdempotencyKey,
    );
  }

  OvertimeSession submit() {
    if (status != OvertimeSessionStatus.reviewing || endedAt == null) {
      throw StateError('Only a reviewing overtime session can be submitted.');
    }
    return OvertimeSession(
      id: id,
      startedAt: startedAt,
      endedAt: endedAt,
      status: OvertimeSessionStatus.pending,
      pausedDuration: pausedDuration,
      startIdempotencyKey: startIdempotencyKey,
      endIdempotencyKey: endIdempotencyKey,
      submitIdempotencyKey: submitIdempotencyKey,
    );
  }

  @override
  List<Object?> get props => [
    id,
    startedAt,
    endedAt,
    status,
    pausedDuration,
    startIdempotencyKey,
    endIdempotencyKey,
    submitIdempotencyKey,
  ];
}

class OvertimeSnapshot extends Equatable {
  const OvertimeSnapshot({required this.history, this.activeSession});

  final OvertimeSession? activeSession;
  final List<OvertimeSession> history;

  @override
  List<Object?> get props => [activeSession, history];
}
