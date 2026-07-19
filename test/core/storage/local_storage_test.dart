import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cedsif_overtime_mobile/core/storage/local_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorage storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    storage = LocalStorage(await SharedPreferences.getInstance());
  });

  test('stores and retrieves supported preference value types', () async {
    await storage.setString('string', 'value');
    await storage.setBool('bool', value: true);
    await storage.setInt('int', 7);
    await storage.setDouble('double', 2.5);
    await storage.setStringList('list', <String>['one', 'two']);

    expect(storage.getString('string'), 'value');
    expect(storage.getBool('bool'), isTrue);
    expect(storage.getInt('int'), 7);
    expect(storage.getDouble('double'), 2.5);
    expect(storage.getStringList('list'), <String>['one', 'two']);
  });

  test('removes one value without clearing other values', () async {
    await storage.setString('remove', 'value');
    await storage.setString('keep', 'value');

    await storage.remove('remove');

    expect(storage.containsKey('remove'), isFalse);
    expect(storage.getString('keep'), 'value');
  });

  test('clears all preferences', () async {
    await storage.setString('first', 'value');
    await storage.setBool('second', value: true);

    await storage.clear();

    expect(storage.containsKey('first'), isFalse);
    expect(storage.containsKey('second'), isFalse);
  });
}
