import 'package:equatable/equatable.dart';

enum OvertimeSessionStatus { active, pending, approved }

class OvertimeSession extends Equatable {
  const OvertimeSession({
    required this.id,
    required this.startedAt,
    required this.status,
    this.endedAt,
  });

  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final OvertimeSessionStatus status;

  Duration durationAt(DateTime now) =>
      (endedAt ?? now).difference(startedAt).isNegative
      ? Duration.zero
      : (endedAt ?? now).difference(startedAt);

  OvertimeSession completeAt(DateTime end) => OvertimeSession(
    id: id,
    startedAt: startedAt,
    endedAt: end,
    status: OvertimeSessionStatus.pending,
  );

  @override
  List<Object?> get props => [id, startedAt, endedAt, status];
}

class OvertimeSnapshot extends Equatable {
  const OvertimeSnapshot({required this.history, this.activeSession});

  final OvertimeSession? activeSession;
  final List<OvertimeSession> history;

  @override
  List<Object?> get props => [activeSession, history];
}
