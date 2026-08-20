import 'package:hive/hive.dart';

abstract interface class SessionDataCleaner {
  Future<void> clear();
}

class LocalSessionDataCleaner implements SessionDataCleaner {
  const LocalSessionDataCleaner({
    required Box<dynamic> cacheBox,
    required Box<dynamic> overtimeBox,
  }) : _cacheBox = cacheBox,
       _overtimeBox = overtimeBox;

  final Box<dynamic> _cacheBox;
  final Box<dynamic> _overtimeBox;

  @override
  Future<void> clear() async {
    await Future.wait<int>(<Future<int>>[
      _cacheBox.clear(),
      _overtimeBox.clear(),
    ]);
  }
}
