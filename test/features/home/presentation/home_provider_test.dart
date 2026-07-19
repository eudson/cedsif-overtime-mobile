import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cedsif_overtime_mobile/core/error/failures.dart';
import 'package:cedsif_overtime_mobile/features/home/domain/entities/home_content.dart';
import 'package:cedsif_overtime_mobile/features/home/domain/usecases/get_home_content_usecase.dart';
import 'package:cedsif_overtime_mobile/features/home/presentation/providers/home_provider.dart';

class _MockGetHomeContentUseCase extends Mock
    implements GetHomeContentUseCase {}

void main() {
  test('load transitions initial to loading to content', () async {
    final completer = Completer<Either<Failure, HomeContent>>();
    final useCase = _MockGetHomeContentUseCase();
    when(useCase.call).thenAnswer((_) => completer.future);
    final container = ProviderContainer(
      overrides: [homeUseCaseProvider.overrideWithValue(useCase)],
    );
    addTearDown(container.dispose);
    expect(container.read(homeNotifierProvider), const HomeState());

    final future = container.read(homeNotifierProvider.notifier).load();
    expect(
      container.read(homeNotifierProvider),
      const HomeState(isLoading: true),
    );
    completer.complete(
      const Right(HomeContent(translationKey: 'home.placeholder')),
    );
    await future;

    expect(
      container.read(homeNotifierProvider),
      const HomeState(content: HomeContent(translationKey: 'home.placeholder')),
    );
  });

  test('load exposes a localization error key on failure', () async {
    final useCase = _MockGetHomeContentUseCase();
    when(
      useCase.call,
    ).thenAnswer((_) async => const Left(NetworkFailure('errors.network')));
    final container = ProviderContainer(
      overrides: [homeUseCaseProvider.overrideWithValue(useCase)],
    );
    addTearDown(container.dispose);

    await container.read(homeNotifierProvider.notifier).load();

    expect(
      container.read(homeNotifierProvider),
      const HomeState(errorKey: 'errors.network'),
    );
  });
}
