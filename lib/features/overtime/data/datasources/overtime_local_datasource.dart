import 'package:hive/hive.dart';

import 'package:cedsif_overtime_mobile/features/overtime/domain/entities/overtime_session.dart';

class OvertimeLocalDataSource {
  const OvertimeLocalDataSource(this._box);

  static const activeSessionKey = 'active_session';
  static const historyKey = 'history';

  final Box<dynamic> _box;

  Future<OvertimeSession?> loadActiveSession() async {
    final value = _box.get(activeSessionKey);
    return value == null ? null : _decode(value);
  }

  Future<void> saveActiveSession(OvertimeSession session) =>
      _box.put(activeSessionKey, _encode(session));

  Future<void> clearActiveSession() => _box.delete(activeSessionKey);

  Future<List<OvertimeSession>> loadHistory() async {
    final value = _box.get(historyKey);
    if (value == null) {
      return const <OvertimeSession>[];
    }
    return (value as List<dynamic>).map(_decode).toList()
      ..sort((left, right) => right.startedAt.compareTo(left.startedAt));
  }

  Future<List<OvertimeSession>> prependHistory(OvertimeSession session) async {
    final history = await loadHistory();
    final updated = [
      session,
      ...history.where((entry) => entry.id != session.id),
    ]..sort((left, right) => right.startedAt.compareTo(left.startedAt));
    await _box.put(historyKey, updated.map(_encode).toList());
    return updated;
  }

  Future<List<OvertimeSession>> replaceHistory(
    List<OvertimeSession> sessions,
  ) async {
    final normalized = [...sessions]
      ..sort((left, right) => right.startedAt.compareTo(left.startedAt));
    await _box.put(historyKey, normalized.map(_encode).toList());
    return normalized;
  }

  static Map<String, dynamic> _encode(OvertimeSession session) => {
    'id': session.id,
    'startedAt': session.startedAt.toIso8601String(),
    'endedAt': session.endedAt?.toIso8601String(),
    'status': session.status.name,
    'pausedDurationSeconds': session.pausedDuration.inSeconds,
    'startIdempotencyKey': session.startIdempotencyKey,
    'endIdempotencyKey': session.endIdempotencyKey,
    'submitIdempotencyKey': session.submitIdempotencyKey,
  };

  static OvertimeSession _decode(dynamic value) {
    final map = Map<String, dynamic>.from(value as Map);
    return OvertimeSession(
      id: map['id'] as String,
      startedAt: DateTime.parse(map['startedAt'] as String),
      endedAt: map['endedAt'] == null
          ? null
          : DateTime.parse(map['endedAt'] as String),
      status: OvertimeSessionStatus.values.byName(map['status'] as String),
      pausedDuration: Duration(
        seconds: (map['pausedDurationSeconds'] as num?)?.toInt() ?? 0,
      ),
      startIdempotencyKey: map['startIdempotencyKey'] as String?,
      endIdempotencyKey: map['endIdempotencyKey'] as String?,
      submitIdempotencyKey: map['submitIdempotencyKey'] as String?,
    );
  }
}
