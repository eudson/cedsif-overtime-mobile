import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cedsif_overtime_mobile/core/config/providers.dart';
import 'package:cedsif_overtime_mobile/core/error/failures.dart';
import 'package:cedsif_overtime_mobile/core/auth/session_scope.dart';
import 'package:cedsif_overtime_mobile/features/profile/data/datasources/profile_local_datasource.dart';
import 'package:cedsif_overtime_mobile/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:cedsif_overtime_mobile/features/profile/data/models/employee_profile_model.dart';
import 'package:cedsif_overtime_mobile/features/profile/domain/entities/employee_profile.dart';
import 'package:cedsif_overtime_mobile/features/profile/domain/repositories/profile_repository.dart';
import 'package:cedsif_overtime_mobile/features/profile/presentation/providers/profile_provider.dart';

class _FakeProfileRepository implements ProfileRepository {
  const _FakeProfileRepository(this.result);

  final Either<Failure, EmployeeProfile> result;

  @override
  Future<Either<Failure, EmployeeProfile>> get() async => result;
}

class _MockBox extends Mock implements Box<dynamic> {}

class _OfflineProfileRemoteDataSource implements ProfileRemoteDataSource {
  @override
  Future<EmployeeProfileModel> get() => throw DioException(
    requestOptions: RequestOptions(path: '/api/v1/me'),
    type: DioExceptionType.connectionError,
  );
}

void main() {
  const profile = EmployeeProfile(
    id: 'employee-1',
    nuit: '123456789',
    firstName: 'Ana',
    lastName: 'Mucavele',
    workUnit: WorkUnitSummary(
      id: 'work-unit-1',
      externalReference: 'UGB-001',
      name: 'Hospital Central de Maputo',
    ),
  );

  test('loads the authenticated employee profile', () async {
    final container = ProviderContainer(
      overrides: <Override>[
        profileRepositoryProvider.overrideWithValue(
          const _FakeProfileRepository(
            Right<Failure, EmployeeProfile>(profile),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(profileProvider.notifier).load();

    expect(container.read(profileProvider).profile, profile);
    expect(container.read(profileProvider).isLoading, isFalse);

    container.read(sessionEpochProvider.notifier).advance();

    expect(container.read(profileProvider).profile, isNull);
    expect(container.read(profileProvider).isLoading, isFalse);
  });

  test(
    'reads the offline profile from the expiry-preserved session box',
    () async {
      final cacheBox = _MockBox();
      final overtimeBox = _MockBox();
      when(
        () => overtimeBox.get(HiveProfileLocalDataSource.profileKey),
      ).thenReturn(<String, Object?>{
        'id': 'employee-1',
        'nuit': '123456789',
        'firstName': 'Ana',
        'lastName': 'Mucavele',
        'workUnit': null,
      });
      final container = ProviderContainer(
        overrides: <Override>[
          profileRemoteDataSourceProvider.overrideWithValue(
            _OfflineProfileRemoteDataSource(),
          ),
          cacheBoxProvider.overrideWithValue(cacheBox),
          overtimeBoxProvider.overrideWithValue(overtimeBox),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(profileRepositoryProvider).get();

      expect(result.getRight().toNullable()?.fullName, 'Ana Mucavele');
      verify(
        () => overtimeBox.get(HiveProfileLocalDataSource.profileKey),
      ).called(1);
      verifyNever(() => cacheBox.get(any<dynamic>()));
    },
  );
}
