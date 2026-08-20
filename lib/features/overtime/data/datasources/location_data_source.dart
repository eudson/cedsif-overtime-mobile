import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:cedsif_overtime_mobile/features/overtime/domain/entities/device_location.dart';

enum LocationPermissionState { granted, denied, blocked }

abstract interface class LocationPlatform {
  Future<bool> isServiceEnabled();

  Future<LocationPermissionState> checkPermission();

  Future<LocationPermissionState> requestPermission();

  Future<DeviceLocation> currentPosition();
}

abstract interface class LocationDataSource {
  Future<DeviceLocation> current();
}

class ForegroundLocationDataSource implements LocationDataSource {
  const ForegroundLocationDataSource(this._platform);

  final LocationPlatform _platform;

  @override
  Future<DeviceLocation> current() async {
    if (!await _platform.isServiceEnabled()) {
      throw const LocationServicesDisabledException();
    }

    var permission = await _platform.checkPermission();
    if (permission == LocationPermissionState.denied) {
      permission = await _platform.requestPermission();
    }
    switch (permission) {
      case LocationPermissionState.granted:
        return _platform.currentPosition();
      case LocationPermissionState.denied:
        throw const LocationPermissionDeniedException();
      case LocationPermissionState.blocked:
        throw const LocationPermissionBlockedException();
    }
  }
}

class PluginLocationPlatform implements LocationPlatform {
  const PluginLocationPlatform();

  static const _settings = LocationSettings(
    accuracy: LocationAccuracy.high,
    timeLimit: Duration(seconds: 15),
  );

  @override
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  @override
  Future<LocationPermissionState> checkPermission() async =>
      _mapPermission(await Permission.locationWhenInUse.status);

  @override
  Future<LocationPermissionState> requestPermission() async =>
      _mapPermission(await Permission.locationWhenInUse.request());

  @override
  Future<DeviceLocation> currentPosition() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: _settings,
    );
    return DeviceLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeters: position.accuracy,
      capturedAt: position.timestamp,
    );
  }

  static LocationPermissionState _mapPermission(PermissionStatus status) {
    if (status.isGranted) {
      return LocationPermissionState.granted;
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      return LocationPermissionState.blocked;
    }
    return LocationPermissionState.denied;
  }
}

sealed class LocationAcquisitionException implements Exception {
  const LocationAcquisitionException();
}

final class LocationServicesDisabledException
    extends LocationAcquisitionException {
  const LocationServicesDisabledException();
}

final class LocationPermissionDeniedException
    extends LocationAcquisitionException {
  const LocationPermissionDeniedException();
}

final class LocationPermissionBlockedException
    extends LocationAcquisitionException {
  const LocationPermissionBlockedException();
}
