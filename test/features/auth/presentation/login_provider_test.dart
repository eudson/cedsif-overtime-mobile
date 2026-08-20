import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cedsif_overtime_mobile/core/error/failures.dart';
import 'package:cedsif_overtime_mobile/core/config/providers.dart';
import 'package:cedsif_overtime_mobile/core/sync/foreground_sync_coordinator.dart';
import 'package:cedsif_overtime_mobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:cedsif_overtime_mobile/features/auth/domain/usecases/logout_usecase.dart';
import 'package:cedsif_overtime_mobile/features/auth/data/services/session_data_cleaner.dart';
import 'package:cedsif_overtime_mobile/features/auth/presentation/providers/login_provider.dart';

class _MockLoginUseCase extends Mock implements LoginUseCase {}

class _MockLogoutUseCase extends Mock implements LogoutUseCase {}

class _MockSessionDataCleaner extends Mock implements SessionDataCleaner {}

class _MockForegroundSyncCoordinator extends Mock
    implements ForegroundSyncCoordinator {}

void main() {
  late _MockLoginUseCase useCase;
  late _MockForegroundSyncCoordinator syncCoordinator;
  late ProviderContainer container;

  setUp(() {
    useCase = _MockLoginUseCase();
    syncCoordinator = _MockForegroundSyncCoordinator();
    container = ProviderContainer(
      overrides: <Override>[
        loginUseCaseProvider.overrideWithValue(useCase),
        foregroundSyncCoordinatorProvider.overrideWithValue(syncCoordinator),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('keeps the facial reference only in session memory', () {
    container
        .read(facialReferenceProvider.notifier)
        .store('SIMULATED-reference-1');

    expect(container.read(facialReferenceProvider), 'SIMULATED-reference-1');
  });

  test('starts idle and exposes loading until login succeeds', () async {
    final completer = Completer<Either<Failure, Unit>>();
    when(
      () => useCase(nuit: '123456789', password: 'secret'),
    ).thenAnswer((_) => completer.future);

    final operation = container
        .read(loginNotifierProvider.notifier)
        .login(nuit: '123456789', password: 'secret');

    expect(container.read(loginNotifierProvider).isLoading, isTrue);
    completer.complete(const Right<Failure, Unit>(unit));
    expect(await operation, isTrue);
    expect(container.read(loginNotifierProvider).isLoading, isFalse);
    expect(container.read(loginNotifierProvider).errorKey, isNull);
    verify(syncCoordinator.requestSync).called(1);
  });

  test('returns false and exposes a typed failure translation key', () async {
    when(() => useCase(nuit: '123456789', password: 'wrong')).thenAnswer(
      (_) async => const Left<Failure, Unit>(
        AuthFailure('auth.invalidCredentials', code: '401'),
      ),
    );

    final succeeded = await container
        .read(loginNotifierProvider.notifier)
        .login(nuit: '123456789', password: 'wrong');

    expect(succeeded, isFalse);
    expect(
      container.read(loginNotifierProvider).errorKey,
      'auth.invalidCredentials',
    );
  });

  test('ignores a duplicate submission while one is active', () async {
    final completer = Completer<Either<Failure, Unit>>();
    when(
      () => useCase(nuit: '123456789', password: 'secret'),
    ).thenAnswer((_) => completer.future);
    final notifier = container.read(loginNotifierProvider.notifier);

    final first = notifier.login(nuit: '123456789', password: 'secret');
    final second = await notifier.login(nuit: '123456789', password: 'secret');
    completer.complete(const Right<Failure, Unit>(unit));

    expect(second, isFalse);
    expect(await first, isTrue);
    verify(() => useCase(nuit: '123456789', password: 'secret')).called(1);
  });

  test('exposes logout progress and success', () async {
    final logoutUseCase = _MockLogoutUseCase();
    final cleaner = _MockSessionDataCleaner();
    final completer = Completer<Either<Failure, Unit>>();
    when(logoutUseCase.call).thenAnswer((_) => completer.future);
    when(cleaner.clear).thenAnswer((_) async {});
    final logoutContainer = ProviderContainer(
      overrides: <Override>[
        logoutUseCaseProvider.overrideWithValue(logoutUseCase),
        sessionDataCleanerProvider.overrideWithValue(cleaner),
      ],
    );
    addTearDown(logoutContainer.dispose);
    logoutContainer
        .read(facialReferenceProvider.notifier)
        .store('SIMULATED-reference-1');

    final operation = logoutContainer
        .read(logoutNotifierProvider.notifier)
        .logout();

    expect(logoutContainer.read(logoutNotifierProvider).isLoading, isTrue);
    completer.complete(const Right<Failure, Unit>(unit));
    expect(await operation, isTrue);
    expect(logoutContainer.read(logoutNotifierProvider).isLoading, isFalse);
    expect(logoutContainer.read(logoutNotifierProvider).errorKey, isNull);
    expect(logoutContainer.read(facialReferenceProvider), isNull);
    verify(cleaner.clear).called(1);
  });

  test('exposes logout failure for localized presentation', () async {
    final logoutUseCase = _MockLogoutUseCase();
    when(logoutUseCase.call).thenAnswer(
      (_) async => const Left<Failure, Unit>(CacheFailure('errors.generic')),
    );
    final logoutContainer = ProviderContainer(
      overrides: <Override>[
        logoutUseCaseProvider.overrideWithValue(logoutUseCase),
      ],
    );
    addTearDown(logoutContainer.dispose);

    final succeeded = await logoutContainer
        .read(logoutNotifierProvider.notifier)
        .logout();

    expect(succeeded, isFalse);
    expect(
      logoutContainer.read(logoutNotifierProvider).errorKey,
      'errors.generic',
    );
  });
}
