import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cedsif_overtime_mobile/core/error/failures.dart';
import 'package:cedsif_overtime_mobile/core/storage/secure_storage.dart';
import 'package:cedsif_overtime_mobile/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:cedsif_overtime_mobile/features/auth/data/models/login_response_model.dart';
import 'package:cedsif_overtime_mobile/features/auth/data/repositories/auth_repository_impl.dart';

class _MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class _MockSecureStorage extends Mock implements SecureStorage {}

void main() {
  late _MockAuthRemoteDataSource dataSource;
  late _MockSecureStorage storage;
  late AuthRepositoryImpl repository;

  setUp(() {
    dataSource = _MockAuthRemoteDataSource();
    storage = _MockSecureStorage();
    repository = AuthRepositoryImpl(dataSource, storage);
  });

  test('stores both tokens only after a successful online login', () async {
    when(
      () => dataSource.login(nuit: '123456789', password: 'secret'),
    ).thenAnswer(
      (_) async => const LoginResponseModel(
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
        expiresIn: 3600,
      ),
    );
    when(
      () => storage.writeTokens(
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
      ),
    ).thenAnswer((_) async {});

    final result = await repository.login(
      nuit: '123456789',
      password: 'secret',
    );

    expect(result, const Right<Failure, Unit>(unit));
    verify(
      () => storage.writeTokens(
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
      ),
    ).called(1);
  });

  test(
    'maps a backend 401 to invalid credentials without storing tokens',
    () async {
      when(
        () => dataSource.login(nuit: '123456789', password: 'wrong'),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/login'),
          response: Response<void>(
            requestOptions: RequestOptions(path: '/auth/login'),
            statusCode: 401,
          ),
        ),
      );

      final result = await repository.login(
        nuit: '123456789',
        password: 'wrong',
      );

      expect(
        result,
        const Left<Failure, Unit>(
          AuthFailure('auth.invalidCredentials', code: '401'),
        ),
      );
      verifyNever(
        () => storage.writeTokens(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
        ),
      );
    },
  );

  test('clears a partial token write and returns a typed failure', () async {
    when(
      () => dataSource.login(nuit: '123456789', password: 'secret'),
    ).thenAnswer(
      (_) async => const LoginResponseModel(
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
        expiresIn: 3600,
      ),
    );
    when(
      () => storage.writeTokens(
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
      ),
    ).thenThrow(StateError('secure storage unavailable'));
    when(storage.clearTokens).thenAnswer((_) async {});

    final result = await repository.login(
      nuit: '123456789',
      password: 'secret',
    );

    expect(result, const Left<Failure, Unit>(ServerFailure('errors.generic')));
    verify(storage.clearTokens).called(1);
  });

  test('clears local tokens and requests refresh-session revocation', () async {
    when(storage.readRefreshToken).thenAnswer((_) async => 'refresh-token');
    when(
      () => dataSource.logout(refreshToken: 'refresh-token'),
    ).thenAnswer((_) async {});
    when(storage.clearTokens).thenAnswer((_) async {});

    final result = await repository.logout();

    expect(result, const Right<Failure, Unit>(unit));
    verifyInOrder([
      () => storage.clearTokens(),
      () => dataSource.logout(refreshToken: 'refresh-token'),
    ]);
  });

  test('clears local tokens when backend logout is unavailable', () async {
    when(storage.readRefreshToken).thenAnswer((_) async => 'refresh-token');
    when(() => dataSource.logout(refreshToken: 'refresh-token')).thenThrow(
      DioException(requestOptions: RequestOptions(path: '/auth/logout')),
    );
    when(storage.clearTokens).thenAnswer((_) async {});

    final result = await repository.logout();

    expect(result, const Right<Failure, Unit>(unit));
    verify(storage.clearTokens).called(1);
  });

  test('does not wait for remote revocation before local logout', () async {
    final remoteRevocation = Completer<void>();
    when(storage.readRefreshToken).thenAnswer((_) async => 'refresh-token');
    when(
      () => dataSource.logout(refreshToken: 'refresh-token'),
    ).thenAnswer((_) => remoteRevocation.future);
    when(storage.clearTokens).thenAnswer((_) async {});

    final result = await repository.logout().timeout(
      const Duration(milliseconds: 100),
    );

    expect(result, const Right<Failure, Unit>(unit));
    verify(storage.clearTokens).called(1);
    remoteRevocation.complete();
  });

  test('reports failure when local credentials cannot be cleared', () async {
    when(storage.readRefreshToken).thenAnswer((_) async => null);
    when(
      storage.clearTokens,
    ).thenThrow(StateError('secure storage unavailable'));

    final result = await repository.logout();

    expect(result, const Left<Failure, Unit>(ServerFailure('errors.generic')));
  });
}
