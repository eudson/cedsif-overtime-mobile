import 'package:fpdart/fpdart.dart';

import 'package:cedsif_overtime_mobile/core/error/failures.dart';

abstract interface class AuthRepository {
  Future<Either<Failure, Unit>> login({
    required String nuit,
    required String password,
  });

  Future<Either<Failure, Unit>> logout();
}
