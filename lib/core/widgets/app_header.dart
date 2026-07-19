import 'package:flutter/material.dart';

import 'package:cedsif_overtime_mobile/core/constants/app_text_styles.dart';
import 'package:cedsif_overtime_mobile/core/constants/constants.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({
    required this.title,
    this.subtitle,
    this.leading,
    this.actions = const <Widget>[],
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppConstants.spacingMedium),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (leading case final value?) ...[
          value,
          const SizedBox(width: AppConstants.spacingMedium),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                label: title,
                child: Text(title, style: AppTextStyles.headline),
              ),
              if (subtitle case final value?) ...[
                const SizedBox(height: AppConstants.spacingSmall),
                Text(value, style: AppTextStyles.body),
              ],
            ],
          ),
        ),
        ...actions,
      ],
    ),
  );
}
