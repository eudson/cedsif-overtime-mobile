import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cedsif_overtime_mobile/core/widgets/widgets.dart';

void main() {
  test('barrel exposes every shared widget', () {
    final widgets = <Widget>[
      const AppBottomSheet(child: SizedBox.shrink()),
      const AppButton(label: 'Action', onPressed: null),
      const AppHeader(title: 'Heading'),
      const AppTextField(label: 'Input'),
      const EmptyStateWidget(icon: Icons.inbox_outlined, title: 'Empty'),
    ];

    expect(widgets.whereType<AppBottomSheet>(), hasLength(1));
    expect(widgets.whereType<AppButton>(), hasLength(1));
    expect(widgets.whereType<AppHeader>(), hasLength(1));
    expect(widgets.whereType<AppTextField>(), hasLength(1));
    expect(widgets.whereType<EmptyStateWidget>(), hasLength(1));
  });
}
