import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cedsif_overtime_mobile/core/config/providers.dart';
import 'package:cedsif_overtime_mobile/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:cedsif_overtime_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:cedsif_overtime_mobile/features/auth/data/services/auth_session_service.dart';
import 'package:cedsif_overtime_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:cedsif_overtime_mobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:cedsif_overtime_mobile/features/auth/domain/usecases/logout_usecase.dart';

class LoginState {
  const LoginState({this.isLoading = false, this.errorKey});

  final bool isLoading;
  final String? errorKey;
}

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
    return result.fold(
      (failure) {
        state = LoginState(errorKey: failure.message);
        return false;
      },
      (_) {
        state = const LoginState();
        return true;
      },
    );
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
    return result.fold(
      (failure) {
        state = LogoutState(errorKey: failure.message);
        return false;
      },
      (_) {
        state = const LogoutState();
        return true;
      },
    );
  }
}

final logoutNotifierProvider = NotifierProvider<LogoutNotifier, LogoutState>(
  LogoutNotifier.new,
);
