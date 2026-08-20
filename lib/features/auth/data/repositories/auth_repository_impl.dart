import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import 'package:cedsif_overtime_mobile/core/error/error_handler.dart';
import 'package:cedsif_overtime_mobile/core/error/failures.dart';
import 'package:cedsif_overtime_mobile/core/storage/secure_storage.dart';
import 'package:cedsif_overtime_mobile/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:cedsif_overtime_mobile/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._dataSource, this._secureStorage);

  final AuthRemoteDataSource _dataSource;
  final SecureStorage _secureStorage;

  @override
  Future<Either<Failure, Unit>> login({
    required String nuit,
    required String password,
  }) async {
    try {
      final response = await _dataSource.login(nuit: nuit, password: password);
      await _secureStorage.writeTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
      return const Right<Failure, Unit>(unit);
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        return const Left<Failure, Unit>(
          AuthFailure('auth.invalidCredentials', code: '401'),
        );
      }
      return Left<Failure, Unit>(ErrorHandler.handle(error));
    } on Object catch (error) {
      await _clearPartialTokens();
      return Left<Failure, Unit>(ErrorHandler.handle(error));
    }
  }

  Future<void> _clearPartialTokens() async {
    try {
      await _secureStorage.clearTokens();
    } on Object {
      // The original secure-storage failure remains the reported failure.
    }
  }
}
