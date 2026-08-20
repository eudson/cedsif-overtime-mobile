import 'package:dio/dio.dart';

import 'package:cedsif_overtime_mobile/core/constants/api_endpoints.dart';
import 'package:cedsif_overtime_mobile/features/auth/data/models/login_response_model.dart';

abstract interface class AuthRemoteDataSource {
  Future<LoginResponseModel> login({
    required String nuit,
    required String password,
  });
}

class DioAuthRemoteDataSource implements AuthRemoteDataSource {
  const DioAuthRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<LoginResponseModel> login({
    required String nuit,
    required String password,
  }) async {
    final response = await _dio.post<dynamic>(
      ApiEndpoints.login,
      data: <String, Object?>{'nuit': nuit, 'password': password},
    );
    final data = response.data;
    if (data is! Map<Object?, Object?>) {
      throw const FormatException('Invalid login response');
    }
    return LoginResponseModel.fromJson(data);
  }
}
