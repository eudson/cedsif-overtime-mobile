import 'package:flutter_test/flutter_test.dart';

import 'package:cedsif_overtime_mobile/features/home/data/models/home_content_model.dart';
import 'package:cedsif_overtime_mobile/features/home/domain/entities/home_content.dart';

void main() {
  test('maps JSON, model, and entity without changing the translation key', () {
    const entity = HomeContent(translationKey: 'home.placeholder');
    final model = HomeContentModel.fromJson(const {
      'translationKey': 'home.placeholder',
    });

    expect(model.toEntity(), entity);
    expect(HomeContentModel.fromEntity(entity), model);
    expect(model.toJson(), {'translationKey': 'home.placeholder'});
  });
}
