import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cedsif_overtime_mobile/core/error/failures.dart';
import 'package:cedsif_overtime_mobile/features/home/domain/entities/home_content.dart';
import 'package:cedsif_overtime_mobile/features/home/domain/repositories/home_repository.dart';
import 'package:cedsif_overtime_mobile/features/home/domain/usecases/get_home_content_usecase.dart';

class _MockHomeRepository extends Mock implements HomeRepository {}

void main() {
  test('delegates content retrieval to the repository', () async {
    final repository = _MockHomeRepository();
    const expected = HomeContent(translationKey: 'home.placeholder');
    when(
      repository.getContent,
    ).thenAnswer((_) async => const Right<Failure, HomeContent>(expected));
    final useCase = GetHomeContentUseCase(repository);

    expect(await useCase(), const Right<Failure, HomeContent>(expected));
    verify(repository.getContent).called(1);
  });
}
