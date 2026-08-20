import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cedsif_overtime_mobile/core/constants/api_endpoints.dart';
import 'package:cedsif_overtime_mobile/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:cedsif_overtime_mobile/features/profile/data/datasources/profile_local_datasource.dart';
import 'package:cedsif_overtime_mobile/features/profile/data/models/employee_profile_model.dart';
import 'package:cedsif_overtime_mobile/features/profile/data/repositories/profile_repository_impl.dart';

class _RecordingAdapter implements HttpClientAdapter {
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      jsonEncode(_profileJson),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _profileJson = <String, Object?>{
  'id': '6ac38f12-d17c-44d1-82c4-48dfef01e2f9',
  'nuit': '123456789',
  'firstName': 'Ana',
  'lastName': 'Mucavele',
  'workUnit': <String, Object?>{
    'id': '07cde809-5634-45cc-8653-34f76ba54dc8',
    'externalReference': 'UGB-001',
    'name': 'Hospital Central de Maputo',
  },
};

void main() {
  test('parses the authenticated employee profile contract', () {
    final profile = EmployeeProfileModel.fromJson(_profileJson).toEntity();

    expect(profile.fullName, 'Ana Mucavele');
    expect(profile.nuit, '123456789');
    expect(profile.workUnit?.externalReference, 'UGB-001');
    expect(profile.workUnit?.name, 'Hospital Central de Maputo');
  });

  test('loads the profile from the authenticated self endpoint', () async {
    final adapter = _RecordingAdapter();
    final dataSource = DioProfileRemoteDataSource(
      Dio()..httpClientAdapter = adapter,
    );

    final model = await dataSource.get();

    expect(adapter.request?.path, ApiEndpoints.employeeProfile);
    expect(adapter.request?.method, 'GET');
    expect(model.nuit, '123456789');
  });

  test('repository exposes a domain profile', () async {
    final dataSource = _FakeProfileRemoteDataSource(
      EmployeeProfileModel.fromJson(_profileJson),
    );
    final localDataSource = _MemoryProfileLocalDataSource();
    final repository = ProfileRepositoryImpl(dataSource, localDataSource);

    final result = await repository.get();

    expect(result.getRight().toNullable()?.fullName, 'Ana Mucavele');
    expect((await localDataSource.get())?.nuit, '123456789');
  });

  test('repository uses the cached profile while offline', () async {
    final cached = EmployeeProfileModel.fromJson(_profileJson);
    final repository = ProfileRepositoryImpl(
      _OfflineProfileRemoteDataSource(),
      _MemoryProfileLocalDataSource(cached),
    );

    final result = await repository.get();

    expect(result.getRight().toNullable()?.fullName, 'Ana Mucavele');
  });
}

class _MemoryProfileLocalDataSource implements ProfileLocalDataSource {
  _MemoryProfileLocalDataSource([this.model]);

  EmployeeProfileModel? model;

  @override
  Future<EmployeeProfileModel?> get() async => model;

  @override
  Future<void> save(EmployeeProfileModel profile) async => model = profile;
}

class _OfflineProfileRemoteDataSource implements ProfileRemoteDataSource {
  @override
  Future<EmployeeProfileModel> get() => throw DioException(
    requestOptions: RequestOptions(path: ApiEndpoints.employeeProfile),
    type: DioExceptionType.connectionError,
  );
}

class _FakeProfileRemoteDataSource implements ProfileRemoteDataSource {
  const _FakeProfileRemoteDataSource(this.model);

  final EmployeeProfileModel model;

  @override
  Future<EmployeeProfileModel> get() async => model;
}
