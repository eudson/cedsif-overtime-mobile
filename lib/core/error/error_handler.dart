import 'dart:io';

import 'package:dio/dio.dart';

import 'package:cedsif_overtime_mobile/core/error/exceptions.dart';
import 'package:cedsif_overtime_mobile/core/error/failures.dart';

abstract final class ErrorHandler {
  static Failure handle(Object error) {
    return switch (error) {
      ServerException(:final message, :final code) => ServerFailure(
        message,
        code: code,
      ),
      NetworkException(:final message, :final code) => NetworkFailure(
        message,
        code: code,
      ),
      CacheException(:final message, :final code) => CacheFailure(
        message,
        code: code,
      ),
      AuthException(:final message, :final code) => AuthFailure(
        message,
        code: code,
      ),
      ValidationException(:final message, :final code) => ValidationFailure(
        message,
        code: code,
      ),
      SocketException() => const NetworkFailure(
        'Network connection unavailable',
      ),
      DioException() => _fromDio(error),
      FormatException() => const ValidationFailure('Invalid data format'),
      _ => const ServerFailure('An unexpected error occurred'),
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
      return const NetworkFailure('Network request failed');
    }

    final statusCode = error.response?.statusCode;
    final code = statusCode?.toString();
    if (statusCode == 401 || statusCode == 403) {
      return AuthFailure('Authentication failed', code: code);
    }
    if (statusCode != null && statusCode >= 400 && statusCode < 500) {
      return ValidationFailure('Request validation failed', code: code);
    }
    return ServerFailure('Server request failed', code: code);
  }
}
