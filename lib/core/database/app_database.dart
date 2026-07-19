import 'package:hive_flutter/hive_flutter.dart';

typedef HiveInitializer = Future<void> Function(HiveInterface hive);

class AppDatabase {
  AppDatabase._({required this.cacheBox, required this.pendingRequestsBox});

  static const cacheBoxName = 'cache';
  static const pendingRequestsBoxName = 'pending_requests';

  final Box<dynamic> cacheBox;
  final Box<dynamic> pendingRequestsBox;
  bool _isClosed = false;

  static Future<AppDatabase> initialize({
    HiveInterface? hive,
    HiveInitializer? hiveInitializer,
  }) async {
    final hiveInstance = hive ?? Hive;
    await (hiveInitializer ?? _initializeHive)(hiveInstance);
    final cacheBox = await hiveInstance.openBox<dynamic>(cacheBoxName);
    final pendingRequestsBox = await hiveInstance.openBox<dynamic>(
      pendingRequestsBoxName,
    );
    return AppDatabase._(
      cacheBox: cacheBox,
      pendingRequestsBox: pendingRequestsBox,
    );
  }

  static Future<void> _initializeHive(HiveInterface hive) => hive.initFlutter();

  Future<void> close() async {
    if (_isClosed) {
      return;
    }
    _isClosed = true;
    await Future.wait<void>(<Future<void>>[
      if (cacheBox.isOpen) cacheBox.close(),
      if (pendingRequestsBox.isOpen) pendingRequestsBox.close(),
    ]);
  }
}
