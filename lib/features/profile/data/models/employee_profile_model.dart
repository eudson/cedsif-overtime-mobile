import 'package:cedsif_overtime_mobile/features/profile/domain/entities/employee_profile.dart';

class WorkUnitSummaryModel {
  const WorkUnitSummaryModel({
    required this.id,
    required this.externalReference,
    required this.name,
  });

  factory WorkUnitSummaryModel.fromJson(Map<Object?, Object?> json) {
    final id = json['id'];
    final externalReference = json['externalReference'];
    final name = json['name'];
    if (id is! String ||
        id.isEmpty ||
        externalReference is! String ||
        externalReference.isEmpty ||
        name is! String ||
        name.isEmpty) {
      throw const FormatException('Invalid work unit response');
    }
    return WorkUnitSummaryModel(
      id: id,
      externalReference: externalReference,
      name: name,
    );
  }

  final String id;
  final String externalReference;
  final String name;

  WorkUnitSummary toEntity() =>
      WorkUnitSummary(id: id, externalReference: externalReference, name: name);

  Map<String, Object?> toJson() => {
    'id': id,
    'externalReference': externalReference,
    'name': name,
  };
}

class EmployeeProfileModel {
  const EmployeeProfileModel({
    required this.id,
    required this.nuit,
    required this.firstName,
    required this.lastName,
    this.workUnit,
  });

  factory EmployeeProfileModel.fromJson(Map<Object?, Object?> json) {
    final id = json['id'];
    final nuit = json['nuit'];
    final firstName = json['firstName'];
    final lastName = json['lastName'];
    final rawWorkUnit = json['workUnit'];
    final workUnit = switch (rawWorkUnit) {
      null => null,
      final Map<Object?, Object?> value => WorkUnitSummaryModel.fromJson(value),
      _ => throw const FormatException('Invalid employee profile response'),
    };
    if (id is! String ||
        id.isEmpty ||
        nuit is! String ||
        nuit.isEmpty ||
        firstName is! String ||
        firstName.isEmpty ||
        lastName is! String ||
        lastName.isEmpty) {
      throw const FormatException('Invalid employee profile response');
    }
    return EmployeeProfileModel(
      id: id,
      nuit: nuit,
      firstName: firstName,
      lastName: lastName,
      workUnit: workUnit,
    );
  }

  final String id;
  final String nuit;
  final String firstName;
  final String lastName;
  final WorkUnitSummaryModel? workUnit;

  Map<String, Object?> toJson() => {
    'id': id,
    'nuit': nuit,
    'firstName': firstName,
    'lastName': lastName,
    'workUnit': workUnit?.toJson(),
  };

  EmployeeProfile toEntity() => EmployeeProfile(
    id: id,
    nuit: nuit,
    firstName: firstName,
    lastName: lastName,
    workUnit: workUnit?.toEntity(),
  );
}
