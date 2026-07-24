import 'package:cedsif_overtime_mobile/widgets/status_chip.dart';

class HistoryEntry {
  const HistoryEntry({
    required this.dateLabel,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.status,
  });

  final String dateLabel;
  final String startTime;
  final String endTime;
  final String duration;
  final AppStatus status;
}
