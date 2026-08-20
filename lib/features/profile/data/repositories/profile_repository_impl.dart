import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import 'package:cedsif_overtime_mobile/core/error/error_handler.dart';
import 'package:cedsif_overtime_mobile/core/error/failures.dart';
import 'package:cedsif_overtime_mobile/features/profile/data/datasources/profile_local_datasource.dart';
import 'package:cedsif_overtime_mobile/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:cedsif_overtime_mobile/features/profile/domain/entities/employee_profile.dart';
import 'package:cedsif_overtime_mobile/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._remoteDataSource, this._localDataSource);

  final ProfileRemoteDataSource _remoteDataSource;
  final ProfileLocalDataSource _localDataSource;

  @override
  Future<Either<Failure, EmployeeProfile>> get() async {
    try {
      final profile = await _remoteDataSource.get();
      await _localDataSource.save(profile);
      return Right(profile.toEntity());
    } on DioException catch (error) {
      final cached = await _localDataSource.get();
      return cached == null
          ? Left(ErrorHandler.handle(error))
          : Right(cached.toEntity());
    } on Object catch (error) {
      return Left(ErrorHandler.handle(error));
    }
  }
}
