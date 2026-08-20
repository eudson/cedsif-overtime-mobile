import 'package:equatable/equatable.dart';

class WorkUnitSummary extends Equatable {
  const WorkUnitSummary({
    required this.id,
    required this.externalReference,
    required this.name,
  });

  final String id;
  final String externalReference;
  final String name;

  @override
  List<Object?> get props => <Object?>[id, externalReference, name];
}

class EmployeeProfile extends Equatable {
  const EmployeeProfile({
    required this.id,
    required this.nuit,
    required this.firstName,
    required this.lastName,
    this.workUnit,
  });

  final String id;
  final String nuit;
  final String firstName;
  final String lastName;
  final WorkUnitSummary? workUnit;

  String get fullName => '$firstName $lastName'.trim();

  @override
  List<Object?> get props => <Object?>[id, nuit, firstName, lastName, workUnit];
}
