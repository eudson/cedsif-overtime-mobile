import 'package:hive/hive.dart';

import 'package:cedsif_overtime_mobile/features/profile/data/models/employee_profile_model.dart';

abstract interface class ProfileLocalDataSource {
  Future<EmployeeProfileModel?> get();

  Future<void> save(EmployeeProfileModel profile);
}

class HiveProfileLocalDataSource implements ProfileLocalDataSource {
  const HiveProfileLocalDataSource(this._box);

  static const profileKey = 'employee_profile';

  final Box<dynamic> _box;

  @override
  Future<EmployeeProfileModel?> get() async {
    final value = _box.get(profileKey);
    if (value == null) {
      return null;
    }
    return EmployeeProfileModel.fromJson(
      Map<Object?, Object?>.from(value as Map),
    );
  }

  @override
  Future<void> save(EmployeeProfileModel profile) =>
      _box.put(profileKey, profile.toJson());
}
