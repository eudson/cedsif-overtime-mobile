import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cedsif_overtime_mobile/core/error/failures.dart';
import 'package:cedsif_overtime_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:cedsif_overtime_mobile/features/auth/domain/usecases/login_usecase.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  test('delegates credentials to the repository', () async {
    final repository = _MockAuthRepository();
    when(
      () => repository.login(nuit: '123456789', password: 'secret'),
    ).thenAnswer((_) async => const Right<Failure, Unit>(unit));
    final useCase = LoginUseCase(repository);

    final result = await useCase(nuit: '123456789', password: 'secret');

    expect(result, const Right<Failure, Unit>(unit));
    verify(
      () => repository.login(nuit: '123456789', password: 'secret'),
    ).called(1);
  });
}
