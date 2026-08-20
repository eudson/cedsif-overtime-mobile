import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cedsif_overtime_mobile/core/config/providers.dart';
import 'package:cedsif_overtime_mobile/core/auth/session_scope.dart';
import 'package:cedsif_overtime_mobile/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:cedsif_overtime_mobile/features/profile/data/datasources/profile_local_datasource.dart';
import 'package:cedsif_overtime_mobile/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:cedsif_overtime_mobile/features/profile/domain/entities/employee_profile.dart';
import 'package:cedsif_overtime_mobile/features/profile/domain/repositories/profile_repository.dart';

class ProfileState {
  const ProfileState({this.isLoading = false, this.profile, this.errorKey});

  final bool isLoading;
  final EmployeeProfile? profile;
  final String? errorKey;
}

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>(
  (ref) => DioProfileRemoteDataSource(ref.watch(dioProvider)),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepositoryImpl(
    ref.watch(profileRemoteDataSourceProvider),
    HiveProfileLocalDataSource(ref.watch(overtimeBoxProvider)),
  ),
);

class ProfileNotifier extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    ref.watch(sessionEpochProvider);
    return const ProfileState();
  }

  Future<void> load() async {
    if (state.isLoading) {
      return;
    }
    state = ProfileState(isLoading: true, profile: state.profile);
    final result = await ref.read(profileRepositoryProvider).get();
    result.fold(
      (failure) => state = ProfileState(
        profile: state.profile,
        errorKey: failure.message,
      ),
      (profile) => state = ProfileState(profile: profile),
    );
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, ProfileState>(
  ProfileNotifier.new,
);
