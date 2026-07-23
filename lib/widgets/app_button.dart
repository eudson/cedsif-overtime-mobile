import 'package:flutter/material.dart';

import 'package:cedsif_overtime_mobile/theme/app_colors.dart';
import 'package:cedsif_overtime_mobile/theme/app_spacing.dart';
import 'package:cedsif_overtime_mobile/theme/app_typography.dart';

enum AppButtonVariant { primary, secondary, destructive }

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.leadingIcon,
    this.icon,
    super.key,
  }) : assert(leadingIcon == null || icon == null);

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? leadingIcon;

  /// Backwards-compatible alias for [leadingIcon].
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final effectiveIcon = leadingIcon ?? icon;
    final foreground = variant == AppButtonVariant.secondary
        ? AppColors.primary
        : AppColors.onPrimary;
    final child = isLoading
        ? SizedBox.square(
            dimension: AppSpacing.iconMedium,
            child: CircularProgressIndicator(
              color: foreground,
              strokeWidth: AppSpacing.progressStrokeWidth,
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (effectiveIcon case final value?) ...[
                Icon(value, size: AppSpacing.iconMedium),
                const SizedBox(width: AppSpacing.space8),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTypography.button.copyWith(color: foreground),
                ),
              ),
            ],
          );

    return Semantics(
      button: true,
      enabled: onPressed != null && !isLoading,
      label: label,
      child: SizedBox(
        width: double.infinity,
        height: AppSpacing.buttonHeight,
        child: switch (variant) {
          AppButtonVariant.secondary => OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            child: child,
          ),
          AppButtonVariant.primary => FilledButton(
            onPressed: isLoading ? null : onPressed,
            child: child,
          ),
          AppButtonVariant.destructive => FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.onPrimary,
              disabledBackgroundColor: AppColors.disabled,
              disabledForegroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
            ),
            onPressed: isLoading ? null : onPressed,
            child: child,
          ),
        },
      ),
    );
  }
}
