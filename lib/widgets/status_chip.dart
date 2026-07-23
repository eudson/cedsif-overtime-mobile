import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:cedsif_overtime_mobile/theme/app_colors.dart';
import 'package:cedsif_overtime_mobile/theme/app_spacing.dart';
import 'package:cedsif_overtime_mobile/theme/app_typography.dart';

enum AppStatus { emCurso, aprovada, pendente, bloqueado, offline }

class StatusChip extends StatelessWidget {
  const StatusChip({required this.status, super.key});

  final AppStatus status;

  @override
  Widget build(BuildContext context) {
    final presentation = _presentation(status);
    final label = presentation.translationKey.tr();
    return Semantics(
      label: label,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: presentation.background,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space12,
            vertical: AppSpacing.space8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (presentation.icon case final icon?) ...[
                Icon(
                  icon,
                  color: presentation.foreground,
                  size: AppSpacing.iconSmall,
                ),
                const SizedBox(width: AppSpacing.space4),
              ],
              Text(
                label,
                style: AppTypography.labelStrong.copyWith(
                  color: presentation.foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

_StatusPresentation _presentation(AppStatus status) => switch (status) {
  AppStatus.emCurso => const _StatusPresentation(
    translationKey: 'status.inProgress',
    foreground: AppColors.successDark,
    background: AppColors.successBackground,
  ),
  AppStatus.aprovada => const _StatusPresentation(
    translationKey: 'status.approved',
    foreground: AppColors.successDark,
    background: AppColors.successBackground,
    icon: Icons.check_rounded,
  ),
  AppStatus.pendente => const _StatusPresentation(
    translationKey: 'status.pending',
    foreground: AppColors.warning,
    background: AppColors.warningBackground,
    icon: Icons.hourglass_top_rounded,
  ),
  AppStatus.bloqueado => const _StatusPresentation(
    translationKey: 'status.blocked',
    foreground: AppColors.danger,
    background: AppColors.dangerBackground,
    icon: Icons.block_rounded,
  ),
  AppStatus.offline => const _StatusPresentation(
    translationKey: 'status.offline',
    foreground: AppColors.offline,
    background: AppColors.offlineBackground,
    icon: Icons.cloud_off_rounded,
  ),
};

class _StatusPresentation {
  const _StatusPresentation({
    required this.translationKey,
    required this.foreground,
    required this.background,
    this.icon,
  });

  final String translationKey;
  final Color foreground;
  final Color background;
  final IconData? icon;
}
