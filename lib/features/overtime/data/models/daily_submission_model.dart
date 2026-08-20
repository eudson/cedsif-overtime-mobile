class DailySubmissionModel {
  const DailySubmissionModel({
    required this.id,
    required this.workDate,
    required this.status,
    required this.entryCount,
    required this.totalDurationSeconds,
  });

  factory DailySubmissionModel.fromJson(Map<Object?, Object?> json) {
    final id = json['id'];
    final workDate = json['workDate'];
    final status = json['status'];
    final entryCount = json['entryCount'];
    final totalDurationSeconds = json['totalDurationSeconds'];
    if (id is! String ||
        id.isEmpty ||
        workDate is! String ||
        !_datePattern.hasMatch(workDate) ||
        status is! String ||
        status.isEmpty ||
        entryCount is! int ||
        entryCount < 0 ||
        totalDurationSeconds is! int ||
        totalDurationSeconds < 0) {
      throw const FormatException('Invalid daily submission response');
    }
    return DailySubmissionModel(
      id: id,
      workDate: workDate,
      status: status,
      entryCount: entryCount,
      totalDurationSeconds: totalDurationSeconds,
    );
  }

  static final RegExp _datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  final String id;
  final String workDate;
  final String status;
  final int entryCount;
  final int totalDurationSeconds;
}
