import 'package:flutter_test/flutter_test.dart';

import 'package:cedsif_overtime_mobile/core/storage/image_cache_manager.dart';

void main() {
  test('declares bounded production cache settings', () {
    expect(ImageCacheManager.cacheKey, 'cedsif_image_cache');
    expect(ImageCacheManager.maxCacheObjects, 200);
    expect(ImageCacheManager.cacheValidity, const Duration(days: 7));
  });
}
