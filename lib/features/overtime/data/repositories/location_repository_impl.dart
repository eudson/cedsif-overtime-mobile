import 'dart:async';

import 'package:fpdart/fpdart.dart';

import 'package:cedsif_overtime_mobile/core/error/failures.dart';
import 'package:cedsif_overtime_mobile/features/overtime/data/datasources/location_data_source.dart';
import 'package:cedsif_overtime_mobile/features/overtime/domain/entities/device_location.dart';
import 'package:cedsif_overtime_mobile/features/overtime/domain/repositories/location_repository.dart';

class LocationRepositoryImpl implements LocationRepository {
  const LocationRepositoryImpl(this._dataSource);

  final LocationDataSource _dataSource;

  @override
  Future<Either<Failure, DeviceLocation>> current() async {
    try {
      return Right(await _dataSource.current());
    } on LocationServicesDisabledException {
      return const Left(
        ValidationFailure(
          'location.servicesDisabled',
          code: 'location_services_disabled',
        ),
      );
    } on LocationPermissionDeniedException {
      return const Left(
        ValidationFailure(
          'location.permissionDenied',
          code: 'location_permission_denied',
        ),
      );
    } on LocationPermissionBlockedException {
      return const Left(
        ValidationFailure(
          'location.permissionBlocked',
          code: 'location_permission_blocked',
        ),
      );
    } on TimeoutException {
      return const Left(
        ValidationFailure('location.timeout', code: 'location_timeout'),
      );
    } on Object {
      return const Left(
        ValidationFailure('location.unavailable', code: 'location_unavailable'),
      );
    }
  }
}
