import 'package:flutter_test/flutter_test.dart';

import 'package:cedsif_overtime_mobile/features/auth/presentation/services/facial_camera.dart';
import 'package:cedsif_overtime_mobile/features/auth/presentation/services/facial_verifier.dart';

void main() {
  final face = CapturedFace(path: '/tmp/face.jpg', delete: () async {});

  test(
    'development verifier returns an explicitly simulated reference',
    () async {
      final verifier = SimulatedFacialVerifier(
        enabled: true,
        referenceFactory: () => 'reference-1',
        delay: Duration.zero,
      );

      expect(await verifier.verify(face), 'SIMULATED-reference-1');
    },
  );

  test(
    'development verifier fails closed when simulation is disabled',
    () async {
      final verifier = SimulatedFacialVerifier(
        enabled: false,
        referenceFactory: () => 'reference-1',
        delay: Duration.zero,
      );

      await expectLater(verifier.verify(face), throwsStateError);
    },
  );
}
