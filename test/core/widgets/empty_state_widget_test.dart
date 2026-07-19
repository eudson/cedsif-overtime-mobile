import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cedsif_overtime_mobile/core/widgets/empty_state_widget.dart';

void main() {
  testWidgets('renders supplied empty state content and action', (
    tester,
  ) async {
    var wasPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyStateWidget(
            icon: Icons.inbox_outlined,
            title: 'Nothing here',
            message: 'Items will appear here.',
            actionLabel: 'Refresh',
            onAction: () => wasPressed = true,
          ),
        ),
      ),
    );

    expect(find.text('Nothing here'), findsOneWidget);
    expect(find.text('Items will appear here.'), findsOneWidget);
    await tester.tap(find.text('Refresh'));
    expect(wasPressed, isTrue);
  });
}
