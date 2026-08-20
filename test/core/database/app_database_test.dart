import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cedsif_overtime_mobile/core/database/app_database.dart';

class _MockHive extends Mock implements HiveInterface {}

class _MockBox extends Mock implements Box<dynamic> {}

void main() {
  test('initializes Hive and opens isolated application boxes', () async {
    final hive = _MockHive();
    final cacheBox = _MockBox();
    final pendingRequestsBox = _MockBox();
    final overtimeBox = _MockBox();
    var initialized = false;
    when(
      () => hive.openBox<dynamic>(AppDatabase.cacheBoxName),
    ).thenAnswer((_) async => cacheBox);
    when(
      () => hive.openBox<dynamic>(AppDatabase.pendingRequestsBoxName),
    ).thenAnswer((_) async => pendingRequestsBox);
    when(
      () => hive.openBox<dynamic>(AppDatabase.overtimeBoxName),
    ).thenAnswer((_) async => overtimeBox);
    when(pendingRequestsBox.toMap).thenReturn(<dynamic, dynamic>{});

    final database = await AppDatabase.initialize(
      hive: hive,
      hiveInitializer: (_) async {
        initialized = true;
      },
    );

    expect(initialized, isTrue);
    expect(database.cacheBox, same(cacheBox));
    expect(database.pendingRequestsBox, same(pendingRequestsBox));
    expect(database.overtimeBox, same(overtimeBox));
  });

  test('closes all owned boxes once', () async {
    final hive = _MockHive();
    final cacheBox = _MockBox();
    final pendingRequestsBox = _MockBox();
    final overtimeBox = _MockBox();
    when(
      () => hive.openBox<dynamic>(AppDatabase.cacheBoxName),
    ).thenAnswer((_) async => cacheBox);
    when(
      () => hive.openBox<dynamic>(AppDatabase.pendingRequestsBoxName),
    ).thenAnswer((_) async => pendingRequestsBox);
    when(
      () => hive.openBox<dynamic>(AppDatabase.overtimeBoxName),
    ).thenAnswer((_) async => overtimeBox);
    when(pendingRequestsBox.toMap).thenReturn(<dynamic, dynamic>{});
    when(() => cacheBox.isOpen).thenReturn(true);
    when(() => pendingRequestsBox.isOpen).thenReturn(true);
    when(() => overtimeBox.isOpen).thenReturn(true);
    when(() => cacheBox.close()).thenAnswer((_) async {});
    when(() => pendingRequestsBox.close()).thenAnswer((_) async {});
    when(() => overtimeBox.close()).thenAnswer((_) async {});
    final database = await AppDatabase.initialize(
      hive: hive,
      hiveInitializer: (_) async {},
    );

    await database.close();
    await database.close();

    verify(() => cacheBox.close()).called(1);
    verify(() => pendingRequestsBox.close()).called(1);
    verify(() => overtimeBox.close()).called(1);
  });
}
