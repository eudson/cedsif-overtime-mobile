import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cedsif_overtime_mobile/core/widgets/app_button.dart';

void main() {
  testWidgets('exposes its label and invokes its callback', (tester) async {
    var presses = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(label: 'Submit', onPressed: () => presses++),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Submit'), findsAtLeastNWidgets(1));
    await tester.tap(find.text('Submit'));
    expect(presses, 1);
  });

  testWidgets('disables interaction while loading', (tester) async {
    var wasPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(
            label: 'Submit',
            isLoading: true,
            onPressed: () => wasPressed = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(AppButton));
    expect(wasPressed, isFalse);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
