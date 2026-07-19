import 'package:flutter/material.dart';

import 'package:cedsif_overtime_mobile/core/constants/app_text_styles.dart';
import 'package:cedsif_overtime_mobile/core/constants/constants.dart';
import 'package:cedsif_overtime_mobile/core/widgets/app_button.dart';

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'actionLabel and onAction must be supplied together',
       );

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppConstants.spacingLarge),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppConstants.iconSizeLarge),
          const SizedBox(height: AppConstants.spacingMedium),
          Text(title, style: AppTextStyles.title, textAlign: TextAlign.center),
          if (message case final value?) ...[
            const SizedBox(height: AppConstants.spacingSmall),
            Text(value, style: AppTextStyles.body, textAlign: TextAlign.center),
          ],
          if (actionLabel case final label?) ...[
            const SizedBox(height: AppConstants.spacingLarge),
            AppButton(label: label, onPressed: onAction),
          ],
        ],
      ),
    ),
  );
}
