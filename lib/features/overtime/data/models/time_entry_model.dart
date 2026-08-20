class TimeEntryModel {
  const TimeEntryModel({
    required this.id,
    required this.workUnitId,
    required this.status,
    required this.startedAt,
    required this.locationVerified,
    this.endedAt,
    this.durationSeconds,
  });

  factory TimeEntryModel.fromJson(Map<Object?, Object?> json) {
    final id = json['id'];
    final workUnitId = json['workUnitId'];
    final status = json['status'];
    final startedAt = json['startedAt'];
    final endedAt = json['endedAt'];
    final durationSeconds = json['durationSeconds'];
    final locationVerified = json['locationVerified'];
    if (id is! String ||
        id.isEmpty ||
        workUnitId is! String ||
        workUnitId.isEmpty ||
        status is! String ||
        status.isEmpty ||
        startedAt is! String ||
        locationVerified is! bool ||
        (endedAt != null && endedAt is! String) ||
        (durationSeconds != null &&
            (durationSeconds is! int || durationSeconds < 0))) {
      throw const FormatException('Invalid time entry response');
    }
    return TimeEntryModel(
      id: id,
      workUnitId: workUnitId,
      status: status,
      startedAt: DateTime.parse(startedAt),
      endedAt: endedAt == null ? null : DateTime.parse(endedAt as String),
      durationSeconds: durationSeconds as int?,
      locationVerified: locationVerified,
    );
  }

  final String id;
  final String workUnitId;
  final String status;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? durationSeconds;
  final bool locationVerified;
}
