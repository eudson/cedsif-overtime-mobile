import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cedsif_overtime_mobile/features/overtime/data/datasources/location_data_source.dart';
import 'package:cedsif_overtime_mobile/features/overtime/data/repositories/location_repository_impl.dart';
import 'package:cedsif_overtime_mobile/features/overtime/presentation/providers/overtime_provider.dart';

void main() {
  test('wires foreground location through the repository boundary', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(locationPlatformProvider),
      isA<PluginLocationPlatform>(),
    );
    expect(
      container.read(locationDataSourceProvider),
      isA<ForegroundLocationDataSource>(),
    );
    expect(
      container.read(locationRepositoryProvider),
      isA<LocationRepositoryImpl>(),
    );
  });
}
