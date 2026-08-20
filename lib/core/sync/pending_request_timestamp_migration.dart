import 'package:hive/hive.dart';

import 'package:cedsif_overtime_mobile/core/constants/api_endpoints.dart';

class PendingRequestTimestampMigration {
  const PendingRequestTimestampMigration(this._box);

  static const legacyOwnerResolutionAttemptedKey =
      'legacyOwnerResolutionAttempted';

  final Box<dynamic> _box;

  Future<void> migrate({String? legacyOwnerSubject}) async {
    Map<dynamic, dynamic> requests;
    try {
      requests = _box.toMap();
    } on Object {
      return;
    }
    for (final entry in requests.entries) {
      final request = _stringKeyedMap(entry.value);
      if (request == null) {
        continue;
      }
      var updatedRequest = request;
      var changed = false;
      var ownershipChanged = false;
      if (request['ownerSubject'] == null &&
          request[legacyOwnerResolutionAttemptedKey] != true) {
        updatedRequest =
            legacyOwnerSubject != null && legacyOwnerSubject.isNotEmpty
            ? <String, Object?>{
                ...updatedRequest,
                'ownerSubject': legacyOwnerSubject,
              }
            : <String, Object?>{
                ...updatedRequest,
                legacyOwnerResolutionAttemptedKey: true,
              };
        changed = true;
        ownershipChanged = true;
      }
      final timestampField = switch (request['path']) {
        ApiEndpoints.overtimeStart => 'startedAt',
        ApiEndpoints.overtimeEnd => 'endedAt',
        _ => null,
      };
      if (timestampField != null) {
        final body = _stringKeyedMap(request['body']);
        final timestamp = body?[timestampField];
        if (body != null && timestamp is String && !_hasOffset(timestamp)) {
          final parsed = DateTime.tryParse(timestamp);
          if (parsed != null) {
            updatedRequest = <String, Object?>{
              ...updatedRequest,
              'body': <String, Object?>{
                ...body,
                timestampField: parsed.toUtc().toIso8601String(),
              },
            };
            changed = true;
          }
        }
      }
      if (!changed) {
        continue;
      }
      try {
        await _box.put(entry.key, updatedRequest);
      } on Object {
        if (ownershipChanged) {
          rethrow;
        }
        // Keep the original request available for a later migration attempt.
      }
    }
  }

  bool _hasOffset(String timestamp) => RegExp(
    r'(?:Z|[+-]\d{2}:\d{2})$',
    caseSensitive: false,
  ).hasMatch(timestamp);

  Map<String, Object?>? _stringKeyedMap(Object? value) {
    if (value is! Map<Object?, Object?>) {
      return null;
    }
    final result = <String, Object?>{};
    for (final entry in value.entries) {
      if (entry.key case final String key) {
        result[key] = entry.value;
      } else {
        return null;
      }
    }
    return result;
  }
}
