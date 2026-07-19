import 'package:flutter_test/flutter_test.dart';

import 'package:cedsif_overtime_mobile/features/home/data/datasources/home_local_datasource.dart';

void main() {
  test('returns only the neutral home placeholder translation key', () async {
    final model = await const HomeLocalDataSource().getContent();
    expect(model.translationKey, 'home.placeholder');
  });
}
