import 'package:fpdart/fpdart.dart';

import 'package:cedsif_overtime_mobile/core/error/failures.dart';
import 'package:cedsif_overtime_mobile/features/home/domain/entities/home_content.dart';
import 'package:cedsif_overtime_mobile/features/home/domain/repositories/home_repository.dart';

class GetHomeContentUseCase {
  const GetHomeContentUseCase(this._repository);

  final HomeRepository _repository;

  Future<Either<Failure, HomeContent>> call() => _repository.getContent();
}
