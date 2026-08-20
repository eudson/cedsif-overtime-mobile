import 'package:equatable/equatable.dart';

class DeviceLocation extends Equatable {
  const DeviceLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.capturedAt,
  });

  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final DateTime capturedAt;

  @override
  List<Object> get props => [latitude, longitude, accuracyMeters, capturedAt];
}
