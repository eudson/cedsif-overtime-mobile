import 'package:flutter_test/flutter_test.dart';

import 'package:cedsif_overtime_mobile/core/error/failures.dart';

void main() {
  test('failures use value equality including their code', () {
    expect(
      const ServerFailure('failed', code: '500'),
      const ServerFailure('failed', code: '500'),
    );
    expect(
      const ServerFailure('failed', code: '500'),
      isNot(const ServerFailure('failed', code: '503')),
    );
  });
}
