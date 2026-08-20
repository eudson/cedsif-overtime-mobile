import 'dart:async';

import 'package:uuid/uuid.dart';

import 'package:cedsif_overtime_mobile/core/config/environment_config.dart';
import 'package:cedsif_overtime_mobile/features/auth/presentation/services/facial_camera.dart';

typedef FacialReferenceFactory = String Function();

abstract interface class FacialVerifier {
  Future<String> verify(CapturedFace face);
}

abstract final class FacialSimulationPolicy {
  static bool isEnabled(AppEnvironment environment) =>
      environment == AppEnvironment.development;
}

class SimulatedFacialVerifier implements FacialVerifier {
  SimulatedFacialVerifier({
    required this.enabled,
    FacialReferenceFactory? referenceFactory,
    this.delay = const Duration(milliseconds: 600),
  }) : _referenceFactory = referenceFactory ?? const Uuid().v4;

  final bool enabled;
  final Duration delay;
  final FacialReferenceFactory _referenceFactory;

  @override
  Future<String> verify(CapturedFace face) async {
    if (!enabled) {
      throw StateError('Simulated facial verification is disabled');
    }
    await Future<void>.delayed(delay);
    return 'SIMULATED-${_referenceFactory()}';
  }
}
