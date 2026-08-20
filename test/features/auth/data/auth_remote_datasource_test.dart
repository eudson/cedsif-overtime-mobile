import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cedsif_overtime_mobile/core/constants/api_endpoints.dart';
import 'package:cedsif_overtime_mobile/features/auth/data/datasources/auth_remote_datasource.dart';

class _RecordingAdapter implements HttpClientAdapter {
  RequestOptions? request;
  Map<String, Object?> responseBody = <String, Object?>{};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      jsonEncode(responseBody),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test(
    'posts NUIT and password and parses the backend login contract',
    () async {
      final adapter = _RecordingAdapter()
        ..responseBody = <String, Object?>{
          'accessToken': 'access-token',
          'refreshToken': 'refresh-token',
          'expiresIn': 3600,
        };
      final dio = Dio()..httpClientAdapter = adapter;
      final dataSource = DioAuthRemoteDataSource(dio);

      final response = await dataSource.login(
        nuit: '123456789',
        password: 'secret',
      );

      expect(adapter.request?.path, ApiEndpoints.login);
      expect(adapter.request?.method, 'POST');
      expect(adapter.request?.data, <String, Object?>{
        'nuit': '123456789',
        'password': 'secret',
      });
      expect(response.accessToken, 'access-token');
      expect(response.refreshToken, 'refresh-token');
      expect(response.expiresIn, 3600);
    },
  );

  test('rejects an incomplete login response', () async {
    final adapter = _RecordingAdapter()
      ..responseBody = <String, Object?>{'accessToken': 'access-token'};
    final dio = Dio()..httpClientAdapter = adapter;
    final dataSource = DioAuthRemoteDataSource(dio);

    await expectLater(
      dataSource.login(nuit: '123456789', password: 'secret'),
      throwsA(isA<FormatException>()),
    );
  });
}
