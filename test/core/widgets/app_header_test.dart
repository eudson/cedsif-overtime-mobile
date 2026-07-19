import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cedsif_overtime_mobile/core/widgets/app_header.dart';

void main() {
  testWidgets('renders caller-provided heading content', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppHeader(title: 'Hours', subtitle: 'This week'),
        ),
      ),
    );

    expect(find.text('Hours'), findsOneWidget);
    expect(find.text('This week'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.header == true,
      ),
      findsOneWidget,
    );
  });
}
