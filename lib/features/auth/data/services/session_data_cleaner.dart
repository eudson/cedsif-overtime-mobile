import 'package:hive/hive.dart';

import 'package:cedsif_overtime_mobile/core/auth/session_mutation_coordinator.dart';

abstract interface class SessionDataCleaner {
  Future<void> clear();

  Future<void> claimSubject(String subject);
}

class LocalSessionDataCleaner implements SessionDataCleaner {
  const LocalSessionDataCleaner({
    required Box<dynamic> cacheBox,
    required Box<dynamic> overtimeBox,
  }) : _cacheBox = cacheBox,
       _overtimeBox = overtimeBox;

  final Box<dynamic> _cacheBox;
  final Box<dynamic> _overtimeBox;

  static const ownerSubjectKey = 'session_data_owner_subject';

  @override
  Future<void> clear() async {
    await Future.wait<int>(<Future<int>>[
      _cacheBox.clear(),
      _overtimeBox.clear(),
    ]);
  }

  @override
  Future<void> claimSubject(String subject) async {
    if (_overtimeBox.get(ownerSubjectKey) == subject) {
      return;
    }
    await clear();
    await _overtimeBox.put(ownerSubjectKey, subject);
  }
}

class SessionDataResetCoordinator {
  SessionDataResetCoordinator(
    this._cleaner, {
    SessionMutationCoordinator? coordinator,
  }) : _coordinator = coordinator ?? SessionMutationCoordinator();

  final SessionDataCleaner _cleaner;
  final SessionMutationCoordinator _coordinator;

  Future<void> clear() => _coordinator.run(_cleaner.clear);

  Future<void> claimSubject(String subject) =>
      _coordinator.run(() => _cleaner.claimSubject(subject));
}
