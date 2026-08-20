import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cedsif_overtime_mobile/core/error/failures.dart';
import 'package:cedsif_overtime_mobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:cedsif_overtime_mobile/features/auth/presentation/providers/login_provider.dart';

class _MockLoginUseCase extends Mock implements LoginUseCase {}

void main() {
  late _MockLoginUseCase useCase;
  late ProviderContainer container;

  setUp(() {
    useCase = _MockLoginUseCase();
    container = ProviderContainer(
      overrides: <Override>[loginUseCaseProvider.overrideWithValue(useCase)],
    );
  });

  tearDown(() => container.dispose());

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
}
