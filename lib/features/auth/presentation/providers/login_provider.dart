import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cedsif_overtime_mobile/core/config/providers.dart';
import 'package:cedsif_overtime_mobile/core/auth/authenticated_subject.dart';
import 'package:cedsif_overtime_mobile/core/auth/session_scope.dart';
import 'package:cedsif_overtime_mobile/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:cedsif_overtime_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:cedsif_overtime_mobile/features/auth/data/services/auth_session_service.dart';
import 'package:cedsif_overtime_mobile/features/auth/data/services/session_data_cleaner.dart';
import 'package:cedsif_overtime_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:cedsif_overtime_mobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:cedsif_overtime_mobile/features/auth/domain/usecases/logout_usecase.dart';

class LoginState {
  const LoginState({this.isLoading = false, this.errorKey});

  final bool isLoading;
  final String? errorKey;
}

class FacialReferenceNotifier extends Notifier<String?> {
  @override
  String? build() {
    ref.watch(sessionEpochProvider);
    return null;
  }

  void store(String reference) => state = reference;

  void clear() => state = null;
}

final facialReferenceProvider =
    NotifierProvider<FacialReferenceNotifier, String?>(
      FacialReferenceNotifier.new,
    );

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => DioAuthRemoteDataSource(ref.watch(dioProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    ref.watch(authRemoteDataSourceProvider),
    ref.watch(secureStorageProvider),
  ),
);

final loginUseCaseProvider = Provider<LoginUseCase>(
  (ref) => LoginUseCase(ref.watch(authRepositoryProvider)),
);

final logoutUseCaseProvider = Provider<LogoutUseCase>(
  (ref) => LogoutUseCase(ref.watch(authRepositoryProvider)),
);

final authSessionServiceProvider = Provider<AuthSessionService>(
  (ref) => AuthSessionService(ref.watch(secureStorageProvider)),
);

final sessionDataCleanerProvider = Provider<SessionDataCleaner>(
  (ref) => LocalSessionDataCleaner(
    cacheBox: ref.watch(cacheBoxProvider),
    overtimeBox: ref.watch(overtimeBoxProvider),
  ),
);

final sessionDataResetCoordinatorProvider =
    Provider<SessionDataResetCoordinator>(
      (ref) =>
          SessionDataResetCoordinator(ref.watch(sessionDataCleanerProvider)),
    );

typedef AuthenticatedSubjectReader = Future<String?> Function();

final authenticatedSubjectReaderProvider = Provider<AuthenticatedSubjectReader>(
  (ref) {
    final secureStorage = ref.watch(secureStorageProvider);
    return () => AuthenticatedSubject.read(secureStorage);
  },
);

class LoginNotifier extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginState();

  Future<bool> login({required String nuit, required String password}) async {
    if (state.isLoading) {
      return false;
    }
    state = const LoginState(isLoading: true);
    final result = await ref.read(loginUseCaseProvider)(
      nuit: nuit,
      password: password,
    );
    final failure = result.getLeft().toNullable();
    if (failure != null) {
      state = LoginState(errorKey: failure.message);
      return false;
    }
    try {
      final subject = await ref.read(authenticatedSubjectReaderProvider)();
      if (subject == null) {
        throw const FormatException('Authenticated token has no subject');
      }
      await ref.read(sessionDataResetCoordinatorProvider).claimSubject(subject);
    } on Object {
      await ref.read(secureStorageProvider).clearTokens();
      state = const LoginState(errorKey: 'errors.generic');
      return false;
    }
    state = const LoginState();
    ref.read(sessionEpochProvider.notifier).advance();
    ref.read(foregroundSyncCoordinatorProvider).requestSync();
    return true;
  }
}

final loginNotifierProvider = NotifierProvider<LoginNotifier, LoginState>(
  LoginNotifier.new,
);

class LogoutState {
  const LogoutState({this.isLoading = false, this.errorKey});

  final bool isLoading;
  final String? errorKey;
}

class LogoutNotifier extends Notifier<LogoutState> {
  @override
  LogoutState build() => const LogoutState();

  Future<bool> logout() async {
    if (state.isLoading) {
      return false;
    }
    state = const LogoutState(isLoading: true);
    final result = await ref.read(logoutUseCaseProvider)();
    final failure = result.getLeft().toNullable();
    if (failure != null) {
      state = LogoutState(errorKey: failure.message);
      return false;
    }
    try {
      await ref.read(sessionDataResetCoordinatorProvider).clear();
    } on Object {
      state = const LogoutState(errorKey: 'errors.generic');
      return false;
    }
    ref.read(sessionEpochProvider.notifier).advance();
    state = const LogoutState();
    return true;
  }
}

final logoutNotifierProvider = NotifierProvider<LogoutNotifier, LogoutState>(
  LogoutNotifier.new,
);
