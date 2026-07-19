import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ImageCacheManager extends CacheManager {
  ImageCacheManager._()
    : super(
        Config(
          cacheKey,
          stalePeriod: cacheValidity,
          maxNrOfCacheObjects: maxCacheObjects,
        ),
      );

  static const cacheKey = 'cedsif_image_cache';
  static const cacheValidity = Duration(days: 7);
  static const maxCacheObjects = 200;

  static final ImageCacheManager _instance = ImageCacheManager._();

  static ImageCacheManager get instance => _instance;
}
