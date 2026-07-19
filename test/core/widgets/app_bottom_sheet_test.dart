import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cedsif_overtime_mobile/core/widgets/app_bottom_sheet.dart';

void main() {
  testWidgets('renders caller-provided title and content', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppBottomSheet(title: 'Details', child: Text('Content')),
        ),
      ),
    );

    expect(find.text('Details'), findsOneWidget);
    expect(find.text('Content'), findsOneWidget);
  });
}
