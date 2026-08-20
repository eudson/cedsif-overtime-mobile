import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cedsif_overtime_mobile/core/config/providers.dart';
import 'package:cedsif_overtime_mobile/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:cedsif_overtime_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:cedsif_overtime_mobile/features/auth/data/services/auth_session_service.dart';
import 'package:cedsif_overtime_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:cedsif_overtime_mobile/features/auth/domain/usecases/login_usecase.dart';

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
