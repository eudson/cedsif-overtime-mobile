import 'package:fpdart/fpdart.dart';

import 'package:cedsif_overtime_mobile/core/error/failures.dart';
import 'package:cedsif_overtime_mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:cedsif_overtime_mobile/features/overtime/domain/entities/device_location.dart';

abstract interface class OvertimeRepository {
  Future<Either<Failure, OvertimeSnapshot>> load();

  Future<Either<Failure, OvertimeSession>> start({
    required DateTime startedAt,
    required DeviceLocation location,
    required String biometricReference,
  });

  Future<Either<Failure, OvertimeSession>> pause(DateTime pausedAt);

  Future<Either<Failure, OvertimeSession>> resume(DateTime resumedAt);

  Future<Either<Failure, OvertimeSnapshot>> submit();
}
