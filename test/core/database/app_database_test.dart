import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cedsif_overtime_mobile/core/database/app_database.dart';

class _MockHive extends Mock implements HiveInterface {}

class _MockBox extends Mock implements Box<dynamic> {}

void main() {
  test('initializes Hive and opens the generic application boxes', () async {
    final hive = _MockHive();
    final cacheBox = _MockBox();
    final pendingRequestsBox = _MockBox();
    var initialized = false;
    when(
      () => hive.openBox<dynamic>(AppDatabase.cacheBoxName),
    ).thenAnswer((_) async => cacheBox);
    when(
      () => hive.openBox<dynamic>(AppDatabase.pendingRequestsBoxName),
    ).thenAnswer((_) async => pendingRequestsBox);

    final database = await AppDatabase.initialize(
      hive: hive,
      hiveInitializer: (_) async {
        initialized = true;
      },
    );

    expect(initialized, isTrue);
    expect(database.cacheBox, same(cacheBox));
    expect(database.pendingRequestsBox, same(pendingRequestsBox));
  });
}
