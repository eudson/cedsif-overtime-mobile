import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cedsif_overtime_mobile/core/error/error_handler.dart';
import 'package:cedsif_overtime_mobile/core/error/exceptions.dart';
import 'package:cedsif_overtime_mobile/core/error/failures.dart';

void main() {
  group('ErrorHandler', () {
    test('maps every application exception to its matching failure', () {
      expect(
        ErrorHandler.handle(const ServerException('server')),
        isA<ServerFailure>(),
      );
      expect(
        ErrorHandler.handle(const NetworkException('offline')),
        isA<NetworkFailure>(),
      );
      expect(
        ErrorHandler.handle(const CacheException('cache')),
        isA<CacheFailure>(),
      );
      expect(
        ErrorHandler.handle(const AuthException('auth')),
        isA<AuthFailure>(),
      );
      expect(
        ErrorHandler.handle(const ValidationException('bad input')),
        isA<ValidationFailure>(),
      );
    });

    test('maps connectivity errors to NetworkFailure', () {
      expect(
        ErrorHandler.handle(const SocketException('offline')),
        isA<NetworkFailure>(),
      );
      expect(
        ErrorHandler.handle(
          DioException(
            requestOptions: RequestOptions(path: '/'),
            type: DioExceptionType.connectionTimeout,
          ),
        ),
        isA<NetworkFailure>(),
      );
    });

    test('maps dio status codes without exposing response bodies', () {
      final request = RequestOptions(path: '/private');
      final unauthorized = DioException(
        requestOptions: request,
        response: Response<dynamic>(
          requestOptions: request,
          statusCode: 401,
          data: 'secret',
        ),
      );
      final badRequest = DioException(
        requestOptions: request,
        response: Response<dynamic>(requestOptions: request, statusCode: 422),
      );

      expect(
        ErrorHandler.handle(unauthorized),
        const AuthFailure('Authentication failed', code: '401'),
      );
      expect(
        ErrorHandler.handle(badRequest),
        const ValidationFailure('Request validation failed', code: '422'),
      );
    });

    test('maps unknown errors to a safe server failure', () {
      final result = ErrorHandler.handle(StateError('sensitive details'));
      expect(result, const ServerFailure('An unexpected error occurred'));
      expect(result.message, isNot(contains('sensitive')));
    });
  });
}
