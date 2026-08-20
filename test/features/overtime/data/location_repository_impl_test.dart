import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'package:cedsif_overtime_mobile/core/error/failures.dart';
import 'package:cedsif_overtime_mobile/features/overtime/data/datasources/location_data_source.dart';
import 'package:cedsif_overtime_mobile/features/overtime/data/repositories/location_repository_impl.dart';
import 'package:cedsif_overtime_mobile/features/overtime/domain/entities/device_location.dart';

class _FakeLocationDataSource implements LocationDataSource {
  DeviceLocation? location;
  Object? error;

  @override
  Future<DeviceLocation> current() async {
    final currentError = error;
    if (currentError != null) {
      throw currentError;
    }
    return location!;
  }
}

void main() {
  late _FakeLocationDataSource dataSource;
  late LocationRepositoryImpl repository;

  setUp(() {
    dataSource = _FakeLocationDataSource();
    repository = LocationRepositoryImpl(dataSource);
  });

  test('returns the current device location', () async {
    final location = DeviceLocation(
      latitude: -25.9681,
      longitude: 32.5732,
      accuracyMeters: 8.5,
      capturedAt: DateTime.utc(2026, 8, 20, 15),
    );
    dataSource.location = location;

    final result = await repository.current();

    expect(result, Right<Failure, DeviceLocation>(location));
  });

  test('maps disabled services to a localized validation failure', () async {
    dataSource.error = const LocationServicesDisabledException();

    final result = await repository.current();

    expect(
      result,
      const Left<Failure, DeviceLocation>(
        ValidationFailure(
          'location.servicesDisabled',
          code: 'location_services_disabled',
        ),
      ),
    );
  });

  test('maps denied permission to a localized validation failure', () async {
    dataSource.error = const LocationPermissionDeniedException();

    final result = await repository.current();

    expect(
      result,
      const Left<Failure, DeviceLocation>(
        ValidationFailure(
          'location.permissionDenied',
          code: 'location_permission_denied',
        ),
      ),
    );
  });

  test('maps blocked permission to an app-settings failure', () async {
    dataSource.error = const LocationPermissionBlockedException();

    final result = await repository.current();

    expect(
      result,
      const Left<Failure, DeviceLocation>(
        ValidationFailure(
          'location.permissionBlocked',
          code: 'location_permission_blocked',
        ),
      ),
    );
  });

  test('maps acquisition timeout to a retryable failure', () async {
    dataSource.error = TimeoutException('location timeout');

    final result = await repository.current();

    expect(
      result,
      const Left<Failure, DeviceLocation>(
        ValidationFailure('location.timeout', code: 'location_timeout'),
      ),
    );
  });

  test('maps unexpected plugin failures without exposing details', () async {
    dataSource.error = StateError('native details');

    final result = await repository.current();

    expect(
      result,
      const Left<Failure, DeviceLocation>(
        ValidationFailure('location.unavailable', code: 'location_unavailable'),
      ),
    );
  });
}
