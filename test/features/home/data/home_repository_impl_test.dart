import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cedsif_overtime_mobile/core/error/exceptions.dart';
import 'package:cedsif_overtime_mobile/core/error/failures.dart';
import 'package:cedsif_overtime_mobile/features/home/data/datasources/home_local_datasource.dart';
import 'package:cedsif_overtime_mobile/features/home/data/models/home_content_model.dart';
import 'package:cedsif_overtime_mobile/features/home/data/repositories/home_repository_impl.dart';
import 'package:cedsif_overtime_mobile/features/home/domain/entities/home_content.dart';

class _MockHomeLocalDataSource extends Mock implements HomeLocalDataSource {}

void main() {
  late _MockHomeLocalDataSource dataSource;
  late HomeRepositoryImpl repository;

  setUp(() {
    dataSource = _MockHomeLocalDataSource();
    repository = HomeRepositoryImpl(dataSource);
  });

  test('returns Right with the domain entity on success', () async {
    when(dataSource.getContent).thenAnswer(
      (_) async => const HomeContentModel(translationKey: 'home.placeholder'),
    );

    expect(
      await repository.getContent(),
      const Right<Failure, HomeContent>(
        HomeContent(translationKey: 'home.placeholder'),
      ),
    );
  });

  test('maps every datasource error to Left', () async {
    when(dataSource.getContent).thenThrow(const NetworkException('offline'));

    expect(
      await repository.getContent(),
      const Left<Failure, HomeContent>(NetworkFailure('errors.network')),
    );
  });
}
