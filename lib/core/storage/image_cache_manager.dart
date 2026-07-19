import 'package:flutter_cache_manager/flutter_cache_manager.dart'
    hide ImageCacheManager;

class ImageCacheManager {
  ImageCacheManager({BaseCacheManager? cacheManager})
    : cacheManager = cacheManager ?? _createDefaultCacheManager();

  static const cacheKey = 'cedsif_image_cache';
  static const cacheValidity = Duration(days: 7);
  static const maxCacheObjects = 200;

  static final ImageCacheManager shared = ImageCacheManager();

  final BaseCacheManager cacheManager;

  static BaseCacheManager get instance => shared.cacheManager;

  static BaseCacheManager _createDefaultCacheManager() => CacheManager(
    Config(
      cacheKey,
      stalePeriod: cacheValidity,
      maxNrOfCacheObjects: maxCacheObjects,
    ),
  );
}
