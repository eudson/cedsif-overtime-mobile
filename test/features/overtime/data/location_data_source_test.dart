import 'package:flutter_test/flutter_test.dart';

import 'package:cedsif_overtime_mobile/features/overtime/data/datasources/location_data_source.dart';
import 'package:cedsif_overtime_mobile/features/overtime/domain/entities/device_location.dart';

class _FakeLocationPlatform implements LocationPlatform {
  bool serviceEnabled = true;
  LocationPermissionState permission = LocationPermissionState.granted;
  LocationPermissionState requestedPermission = LocationPermissionState.granted;
  int requestCalls = 0;
  int positionCalls = 0;
  DeviceLocation position = DeviceLocation(
    latitude: -25.9681,
    longitude: 32.5732,
    accuracyMeters: 8.5,
    capturedAt: DateTime.utc(2026, 8, 20, 15),
  );

  @override
  Future<bool> isServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermissionState> checkPermission() async => permission;

  @override
  Future<LocationPermissionState> requestPermission() async {
    requestCalls += 1;
    return requestedPermission;
  }

  @override
  Future<DeviceLocation> currentPosition() async {
    positionCalls += 1;
    return position;
  }
}

void main() {
  late _FakeLocationPlatform platform;
  late ForegroundLocationDataSource dataSource;

  setUp(() {
    platform = _FakeLocationPlatform();
    dataSource = ForegroundLocationDataSource(platform);
  });

  test('returns a fresh position when permission is already granted', () async {
    final location = await dataSource.current();

    expect(location, platform.position);
    expect(platform.requestCalls, 0);
    expect(platform.positionCalls, 1);
  });

  test('requests permission before reading the current position', () async {
    platform.permission = LocationPermissionState.denied;

    final location = await dataSource.current();

    expect(location, platform.position);
    expect(platform.requestCalls, 1);
    expect(platform.positionCalls, 1);
  });

  test('fails when device location services are disabled', () async {
    platform.serviceEnabled = false;

    await expectLater(
      dataSource.current(),
      throwsA(isA<LocationServicesDisabledException>()),
    );
    expect(platform.positionCalls, 0);
  });

  test('fails when the user denies the runtime permission', () async {
    platform.permission = LocationPermissionState.denied;
    platform.requestedPermission = LocationPermissionState.denied;

    await expectLater(
      dataSource.current(),
      throwsA(isA<LocationPermissionDeniedException>()),
    );
    expect(platform.positionCalls, 0);
  });

  test('does not prompt again when location permission is blocked', () async {
    platform.permission = LocationPermissionState.blocked;

    await expectLater(
      dataSource.current(),
      throwsA(isA<LocationPermissionBlockedException>()),
    );
    expect(platform.requestCalls, 0);
    expect(platform.positionCalls, 0);
  });
}
