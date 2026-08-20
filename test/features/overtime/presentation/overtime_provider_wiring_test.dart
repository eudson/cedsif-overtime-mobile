import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';

import 'package:cedsif_overtime_mobile/core/config/providers.dart';
import 'package:cedsif_overtime_mobile/core/database/app_database.dart';
import 'package:cedsif_overtime_mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:cedsif_overtime_mobile/features/overtime/data/datasources/overtime_remote_datasource.dart';
import 'package:cedsif_overtime_mobile/features/overtime/presentation/providers/overtime_provider.dart';

class _MockDatabase extends Mock implements AppDatabase {}

class _MockBox extends Mock implements Box<dynamic> {}

void main() {
  test('wires overtime persistence to its feature-owned box', () async {
    final database = _MockDatabase();
    final cacheBox = _MockBox();
    final overtimeBox = _MockBox();
    when(() => database.cacheBox).thenReturn(cacheBox);
    when(() => database.overtimeBox).thenReturn(overtimeBox);
    when(
      () => overtimeBox.put(any<dynamic>(), any<dynamic>()),
    ).thenAnswer((_) async {});
    when(
      () => cacheBox.put(any<dynamic>(), any<dynamic>()),
    ).thenAnswer((_) async {});
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);
    final session = OvertimeSession(
      id: 'entry-1',
      startedAt: DateTime.utc(2026, 8, 20, 16),
      status: OvertimeSessionStatus.active,
    );

    await container
        .read(overtimeLocalDataSourceProvider)
        .saveActiveSession(session);

    verify(() => overtimeBox.put('active_session', any<dynamic>())).called(1);
    verifyNever(() => cacheBox.put(any<dynamic>(), any<dynamic>()));
  });

  test('wires overtime API calls through the shared authenticated Dio', () {
    final dio = Dio();
    final container = ProviderContainer(
      overrides: [dioProvider.overrideWithValue(dio)],
    );
    addTearDown(container.dispose);

    expect(
      container.read(overtimeRemoteDataSourceProvider),
      isA<DioOvertimeRemoteDataSource>(),
    );
  });
}
