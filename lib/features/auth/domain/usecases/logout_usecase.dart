import 'package:fpdart/fpdart.dart';

import 'package:cedsif_overtime_mobile/core/error/failures.dart';
import 'package:cedsif_overtime_mobile/features/auth/domain/repositories/auth_repository.dart';

class LogoutUseCase {
  const LogoutUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, Unit>> call() => _repository.logout();
}
