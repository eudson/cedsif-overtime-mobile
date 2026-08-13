import 'package:hive/hive.dart';

import 'package:cedsif_overtime_mobile/features/overtime/domain/entities/overtime_session.dart';

class OvertimeLocalDataSource {
  const OvertimeLocalDataSource(this._box);

  static const activeSessionKey = 'demo_overtime_active_session';
  static const historyKey = 'demo_overtime_history';

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
      final seeded = _seedHistory();
      await _box.put(historyKey, seeded.map(_encode).toList());
      return seeded;
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

  static Map<String, dynamic> _encode(OvertimeSession session) => {
    'id': session.id,
    'startedAt': session.startedAt.toIso8601String(),
    'endedAt': session.endedAt?.toIso8601String(),
    'status': session.status.name,
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
    );
  }

  static List<OvertimeSession> _seedHistory() => [
    OvertimeSession(
      id: 'seed-2026-07-18',
      startedAt: DateTime(2026, 7, 18, 8, 24),
      endedAt: DateTime(2026, 7, 18, 11, 11),
      status: OvertimeSessionStatus.pending,
    ),
    OvertimeSession(
      id: 'seed-2026-07-15',
      startedAt: DateTime(2026, 7, 15, 17),
      endedAt: DateTime(2026, 7, 15, 21, 6),
      status: OvertimeSessionStatus.approved,
    ),
    OvertimeSession(
      id: 'seed-2026-07-11',
      startedAt: DateTime(2026, 7, 11, 18),
      endedAt: DateTime(2026, 7, 11, 22, 24),
      status: OvertimeSessionStatus.approved,
    ),
    OvertimeSession(
      id: 'seed-2026-07-08',
      startedAt: DateTime(2026, 7, 8, 18, 30),
      endedAt: DateTime(2026, 7, 8, 21),
      status: OvertimeSessionStatus.approved,
    ),
  ];
}
