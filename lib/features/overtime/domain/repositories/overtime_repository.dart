import 'package:fpdart/fpdart.dart';

import 'package:cedsif_overtime_mobile/core/error/failures.dart';
import 'package:cedsif_overtime_mobile/features/overtime/domain/entities/overtime_session.dart';

abstract interface class OvertimeRepository {
  Future<Either<Failure, OvertimeSnapshot>> load();

  Future<Either<Failure, OvertimeSession>> start(DateTime startedAt);

  Future<Either<Failure, OvertimeSnapshot>> stop(DateTime endedAt);
}
