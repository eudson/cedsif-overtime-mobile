import 'package:flutter_test/flutter_test.dart';

import 'package:cedsif_overtime_mobile/features/home/domain/entities/home_content.dart';

void main() {
  test('uses value equality for its translation key', () {
    expect(
      const HomeContent(translationKey: 'home.placeholder'),
      const HomeContent(translationKey: 'home.placeholder'),
    );
  });
}
