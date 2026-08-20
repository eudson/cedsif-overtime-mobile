import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import 'package:cedsif_overtime_mobile/core/error/error_handler.dart';
import 'package:cedsif_overtime_mobile/core/auth/session_mutation_coordinator.dart';
import 'package:cedsif_overtime_mobile/core/error/failures.dart';
import 'package:cedsif_overtime_mobile/core/storage/secure_storage.dart';
import 'package:cedsif_overtime_mobile/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:cedsif_overtime_mobile/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(
    this._dataSource,
    this._secureStorage, {
    SessionMutationCoordinator? sessionMutationCoordinator,
  }) : _sessionMutationCoordinator =
           sessionMutationCoordinator ?? SessionMutationCoordinator.shared;

  final AuthRemoteDataSource _dataSource;
  final SecureStorage _secureStorage;
  final SessionMutationCoordinator _sessionMutationCoordinator;

  @override
  Future<Either<Failure, Unit>> login({
    required String nuit,
    required String password,
  }) async {
    try {
      final response = await _dataSource.login(nuit: nuit, password: password);
      await _sessionMutationCoordinator.run(
        () => _secureStorage.writeTokens(
          accessToken: response.accessToken,
          refreshToken: response.refreshToken,
        ),
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

  @override
  Future<Either<Failure, Unit>> logout() async {
    String? refreshToken;
    try {
      await _sessionMutationCoordinator.run(() async {
        try {
          refreshToken = await _secureStorage.readRefreshToken();
        } on Object {
          // Local sign-out still proceeds if the stored token cannot be read.
        }
        await _secureStorage.clearTokens();
      });
    } on Object catch (error) {
      return Left<Failure, Unit>(ErrorHandler.handle(error));
    }

    final tokenToRevoke = refreshToken;
    if (tokenToRevoke != null && tokenToRevoke.isNotEmpty) {
      unawaited(_revokeRemoteSession(tokenToRevoke));
    }
    return const Right<Failure, Unit>(unit);
  }

  Future<void> _revokeRemoteSession(String refreshToken) async {
    try {
      await _dataSource.logout(refreshToken: refreshToken);
    } on Object {
      // CEDSIF-CONFIRM: local sign-out remains available offline; remote
      // revocation then relies on the refresh session's server-side expiry.
    }
  }

  Future<void> _clearPartialTokens() async {
    try {
      await _sessionMutationCoordinator.run(_secureStorage.clearTokens);
    } on Object {
      // The original secure-storage failure remains the reported failure.
    }
  }
}
