import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cedsif_overtime_mobile/core/error/failures.dart';
import 'package:cedsif_overtime_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:cedsif_overtime_mobile/features/auth/domain/usecases/logout_usecase.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  test('delegates logout to the repository', () async {
    final repository = _MockAuthRepository();
    when(
      repository.logout,
    ).thenAnswer((_) async => const Right<Failure, Unit>(unit));
    final useCase = LogoutUseCase(repository);

    final result = await useCase();

    expect(result, const Right<Failure, Unit>(unit));
    verify(repository.logout).called(1);
  });
}
