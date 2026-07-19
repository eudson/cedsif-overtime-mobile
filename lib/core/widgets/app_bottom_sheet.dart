import 'package:flutter/material.dart';

import 'package:cedsif_overtime_mobile/core/constants/app_text_styles.dart';
import 'package:cedsif_overtime_mobile/core/constants/constants.dart';

class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({required this.child, this.title, super.key});

  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(AppConstants.spacingLarge),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title case final value?) ...[
            Semantics(
              header: true,
              child: Text(value, style: AppTextStyles.title),
            ),
            const SizedBox(height: AppConstants.spacingMedium),
          ],
          child,
        ],
      ),
    ),
  );
}
