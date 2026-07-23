import 'package:flutter/material.dart';

import 'package:cedsif_overtime_mobile/theme/app_colors.dart';
import 'package:cedsif_overtime_mobile/theme/app_spacing.dart';
import 'package:cedsif_overtime_mobile/theme/app_typography.dart';

class InfoCard extends StatelessWidget {
  const InfoCard({
    required this.label,
    required this.value,
    this.leadingIcon,
    this.trailingIcon,
    this.backgroundColor = AppColors.surface,
    this.valueStyle,
    super.key,
  });

  final String label;
  final String value;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final Color backgroundColor;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label, $value',
    container: true,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(
          color: AppColors.border,
          width: AppSpacing.borderWidth,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space16),
        child: Row(
          children: [
            if (leadingIcon case final icon?) ...[
              Icon(
                icon,
                color: AppColors.secondary,
                size: AppSpacing.iconMedium,
              ),
              const SizedBox(width: AppSpacing.space12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: AppTypography.small),
                  const SizedBox(height: AppSpacing.space4),
                  Text(value, style: valueStyle ?? AppTypography.labelStrong),
                ],
              ),
            ),
            if (trailingIcon case final icon?) ...[
              const SizedBox(width: AppSpacing.space12),
              Icon(icon, color: AppColors.success, size: AppSpacing.iconMedium),
            ],
          ],
        ),
      ),
    ),
  );
}
