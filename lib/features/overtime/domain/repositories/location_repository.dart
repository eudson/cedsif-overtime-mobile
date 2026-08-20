import 'package:fpdart/fpdart.dart';

import 'package:cedsif_overtime_mobile/core/error/failures.dart';
import 'package:cedsif_overtime_mobile/features/overtime/domain/entities/device_location.dart';

abstract interface class LocationRepository {
  Future<Either<Failure, DeviceLocation>> current();
}
