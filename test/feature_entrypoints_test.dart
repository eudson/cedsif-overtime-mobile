import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cedsif_overtime_mobile/features/auth/login_screen.dart';
import 'package:cedsif_overtime_mobile/features/home/home_screen.dart';

void main() {
  test('exposes the requested Login and Home screen entrypoints', () {
    const screens = <Widget>[LoginScreen(), HomeScreen()];

    expect(screens.whereType<LoginScreen>(), hasLength(1));
    expect(screens.whereType<HomeScreen>(), hasLength(1));
  });
}
