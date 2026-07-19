import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cedsif_overtime_mobile/core/widgets/app_text_field.dart';

void main() {
  testWidgets('forwards labels and text changes to the caller', (tester) async {
    String? value;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppTextField(label: 'Name', onChanged: (text) => value = text),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Name'), findsAtLeastNWidgets(1));
    await tester.enterText(find.byType(TextField), 'Ana');
    expect(value, 'Ana');
  });
}
