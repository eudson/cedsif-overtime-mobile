import 'package:flutter/material.dart';

import 'package:cedsif_overtime_mobile/core/constants/app_text_styles.dart';
import 'package:cedsif_overtime_mobile/core/constants/constants.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox.square(
            dimension: AppConstants.spacingMedium,
            child: CircularProgressIndicator(),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon case final value?) ...[
                Icon(value),
                const SizedBox(width: AppConstants.spacingSmall),
              ],
              Text(label, style: AppTextStyles.label),
            ],
          );

    return Semantics(
      button: true,
      label: label,
      child: SizedBox(
        height: AppConstants.buttonHeight,
        child: FilledButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        ),
      ),
    );
  }
}
