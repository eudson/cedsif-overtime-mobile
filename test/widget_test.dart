import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cedsif_overtime_mobile/main.dart' as app;

void main() {
  testWidgets('boots the Flutter root widget', (WidgetTester tester) async {
    app.main();
    await tester.pump();

    expect(find.byKey(const Key('bootstrap-root')), findsOneWidget);
  });
}
