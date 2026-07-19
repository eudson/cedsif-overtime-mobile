import 'package:flutter_cache_manager/flutter_cache_manager.dart'
    hide ImageCacheManager;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cedsif_overtime_mobile/core/storage/image_cache_manager.dart';

class _MockBaseCacheManager extends Mock implements BaseCacheManager {}

void main() {
  test('uses an injected cache manager', () {
    final delegate = _MockBaseCacheManager();

    final manager = ImageCacheManager(cacheManager: delegate);

    expect(manager.cacheManager, same(delegate));
  });

  test('declares bounded production cache settings', () {
    expect(ImageCacheManager.cacheKey, 'cedsif_image_cache');
    expect(ImageCacheManager.maxCacheObjects, 200);
    expect(ImageCacheManager.cacheValidity, const Duration(days: 7));
  });
}
