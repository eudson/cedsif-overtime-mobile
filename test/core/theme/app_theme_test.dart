import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cedsif_overtime_mobile/core/theme/app_theme.dart';

void main() {
  test('exposes reachable default light and dark themes', () {
    expect(AppTheme.light.brightness, Brightness.light);
    expect(AppTheme.dark.brightness, Brightness.dark);
    expect(AppTheme.light.useMaterial3, isTrue);
    expect(AppTheme.dark.useMaterial3, isTrue);
  });
}
