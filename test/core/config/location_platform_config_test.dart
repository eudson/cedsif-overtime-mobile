import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('declares foreground-only Android location permissions', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(manifest, contains('android.permission.ACCESS_COARSE_LOCATION'));
    expect(manifest, contains('android.permission.ACCESS_FINE_LOCATION'));
    expect(
      manifest,
      isNot(contains('android.permission.ACCESS_BACKGROUND_LOCATION')),
    );
  });

  test('declares only when-in-use iOS location access', () {
    final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();
    final podfile = File('ios/Podfile').readAsStringSync();

    expect(infoPlist, contains('NSLocationWhenInUseUsageDescription'));
    expect(infoPlist, isNot(contains('NSLocationAlwaysUsageDescription')));
    expect(podfile, contains('PERMISSION_LOCATION_WHENINUSE=1'));
    expect(podfile, contains('BYPASS_PERMISSION_LOCATION_ALWAYS=1'));
  });

  test('localizes the iOS location permission rationale', () {
    for (final locale in ['en', 'pt', 'es']) {
      final strings = File(
        'ios/Runner/$locale.lproj/InfoPlist.strings',
      ).readAsStringSync();

      expect(
        strings,
        contains('"NSLocationWhenInUseUsageDescription"'),
        reason: 'missing $locale location rationale',
      );
    }
  });
}
