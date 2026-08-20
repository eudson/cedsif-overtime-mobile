import 'package:dio/dio.dart';

import 'package:cedsif_overtime_mobile/core/constants/api_endpoints.dart';
import 'package:cedsif_overtime_mobile/features/profile/data/models/employee_profile_model.dart';

abstract interface class ProfileRemoteDataSource {
  Future<EmployeeProfileModel> get();
}

class DioProfileRemoteDataSource implements ProfileRemoteDataSource {
  const DioProfileRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<EmployeeProfileModel> get() async {
    final response = await _dio.get<dynamic>(ApiEndpoints.employeeProfile);
    final data = response.data;
    if (data is! Map<Object?, Object?>) {
      throw const FormatException('Invalid employee profile response');
    }
    return EmployeeProfileModel.fromJson(data);
  }
}
