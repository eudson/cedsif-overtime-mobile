import 'package:fpdart/fpdart.dart';

import 'package:cedsif_overtime_mobile/core/error/failures.dart';
import 'package:cedsif_overtime_mobile/features/profile/domain/entities/employee_profile.dart';

abstract interface class ProfileRepository {
  Future<Either<Failure, EmployeeProfile>> get();
}
