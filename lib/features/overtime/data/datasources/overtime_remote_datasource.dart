import 'package:dio/dio.dart';

import 'package:cedsif_overtime_mobile/core/constants/api_endpoints.dart';
import 'package:cedsif_overtime_mobile/features/overtime/data/models/daily_submission_model.dart';
import 'package:cedsif_overtime_mobile/features/overtime/data/models/time_entry_model.dart';

abstract interface class OvertimeRemoteDataSource {
  Future<TimeEntryModel> start({
    required String timeEntryId,
    required double latitude,
    required double longitude,
    required String biometricReference,
    required DateTime startedAt,
    required String idempotencyKey,
  });

  Future<TimeEntryModel> end({
    required String timeEntryId,
    required DateTime endedAt,
    required String idempotencyKey,
  });

  Future<List<TimeEntryModel>> history();

  Future<DailySubmissionModel> submit({
    required DateTime workDate,
    required String idempotencyKey,
  });
}

class DioOvertimeRemoteDataSource implements OvertimeRemoteDataSource {
  const DioOvertimeRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<TimeEntryModel> start({
    required String timeEntryId,
    required double latitude,
    required double longitude,
    required String biometricReference,
    required DateTime startedAt,
    required String idempotencyKey,
  }) async {
    final response = await _dio.post<dynamic>(
      ApiEndpoints.overtimeStart,
      data: <String, Object?>{
        'timeEntryId': timeEntryId,
        'latitude': latitude,
        'longitude': longitude,
        'biometricReference': biometricReference,
        'startedAt': startedAt.toUtc().toIso8601String(),
      },
      options: _idempotentOptions(idempotencyKey),
    );
    return TimeEntryModel.fromJson(_responseMap(response.data));
  }

  @override
  Future<TimeEntryModel> end({
    required String timeEntryId,
    required DateTime endedAt,
    required String idempotencyKey,
  }) async {
    final response = await _dio.post<dynamic>(
      ApiEndpoints.overtimeEnd,
      data: <String, Object?>{
        'timeEntryId': timeEntryId,
        'endedAt': endedAt.toUtc().toIso8601String(),
      },
      options: _idempotentOptions(idempotencyKey),
    );
    return TimeEntryModel.fromJson(_responseMap(response.data));
  }

  @override
  Future<List<TimeEntryModel>> history() async {
    final response = await _dio.get<dynamic>(ApiEndpoints.overtimeHistory);
    final data = response.data;
    if (data is! List<Object?>) {
      throw const FormatException('Invalid overtime history response');
    }
    return data
        .map((item) => TimeEntryModel.fromJson(_responseMap(item)))
        .toList();
  }

  @override
  Future<DailySubmissionModel> submit({
    required DateTime workDate,
    required String idempotencyKey,
  }) async {
    final response = await _dio.post<dynamic>(
      ApiEndpoints.overtimeSubmit,
      data: <String, Object?>{'workDate': _formatDate(workDate)},
      options: _idempotentOptions(idempotencyKey),
    );
    return DailySubmissionModel.fromJson(_responseMap(response.data));
  }

  static Options _idempotentOptions(String idempotencyKey) =>
      Options(headers: <String, Object?>{'Idempotency-Key': idempotencyKey});

  static Map<Object?, Object?> _responseMap(Object? data) {
    if (data is! Map<Object?, Object?>) {
      throw const FormatException('Invalid overtime response');
    }
    return data;
  }

  static String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
