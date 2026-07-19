import 'dart:io';

import 'package:dio/dio.dart';

import 'package:cedsif_overtime_mobile/core/error/exceptions.dart';
import 'package:cedsif_overtime_mobile/core/error/failures.dart';

abstract final class ErrorHandler {
  static Failure handle(Object error) {
    return switch (error) {
      ServerException(:final code) => ServerFailure(
        'errors.generic',
        code: code,
      ),
      NetworkException(:final code) => NetworkFailure(
        'errors.network',
        code: code,
      ),
      CacheException(:final code) => CacheFailure('errors.generic', code: code),
      AuthException(:final code) => AuthFailure(
        'errors.sessionExpired',
        code: code,
      ),
      ValidationException(:final code) => ValidationFailure(
        'errors.generic',
        code: code,
      ),
      SocketException() => const NetworkFailure('errors.network'),
      DioException() => _fromDio(error),
      FormatException() => const ValidationFailure('errors.generic'),
      _ => const ServerFailure('errors.generic'),
    };
  }

  static Failure _fromDio(DioException error) {
    if (switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError => true,
      _ => false,
    }) {
      return const NetworkFailure('errors.network');
    }

    final statusCode = error.response?.statusCode;
    final code = statusCode?.toString();
    if (statusCode == 401 || statusCode == 403) {
      return AuthFailure('errors.sessionExpired', code: code);
    }
    if (statusCode != null && statusCode >= 400 && statusCode < 500) {
      return ValidationFailure('errors.generic', code: code);
    }
    return ServerFailure('errors.generic', code: code);
  }
}
