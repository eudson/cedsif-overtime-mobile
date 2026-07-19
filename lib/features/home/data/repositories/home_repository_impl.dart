import 'package:fpdart/fpdart.dart';

import 'package:cedsif_overtime_mobile/core/error/error_handler.dart';
import 'package:cedsif_overtime_mobile/core/error/failures.dart';
import 'package:cedsif_overtime_mobile/features/home/data/datasources/home_local_datasource.dart';
import 'package:cedsif_overtime_mobile/features/home/domain/entities/home_content.dart';
import 'package:cedsif_overtime_mobile/features/home/domain/repositories/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  const HomeRepositoryImpl(this._dataSource);

  final HomeLocalDataSource _dataSource;

  @override
  Future<Either<Failure, HomeContent>> getContent() async {
    try {
      final model = await _dataSource.getContent();
      return Right(model.toEntity());
    } on Object catch (error) {
      return Left(ErrorHandler.handle(error));
    }
  }
}
