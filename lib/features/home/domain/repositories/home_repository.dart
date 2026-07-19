import 'package:fpdart/fpdart.dart';

import 'package:cedsif_overtime_mobile/core/error/failures.dart';
import 'package:cedsif_overtime_mobile/features/home/domain/entities/home_content.dart';

abstract interface class HomeRepository {
  Future<Either<Failure, HomeContent>> getContent();
}
