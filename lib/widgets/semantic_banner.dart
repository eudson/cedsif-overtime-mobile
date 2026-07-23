import 'package:flutter/material.dart';

import 'package:cedsif_overtime_mobile/theme/app_colors.dart';
import 'package:cedsif_overtime_mobile/theme/app_spacing.dart';
import 'package:cedsif_overtime_mobile/theme/app_typography.dart';

enum SemanticBannerKind { ok, warning, danger }

class SemanticBanner extends StatelessWidget {
  const SemanticBanner({required this.kind, required this.message, super.key});

  final SemanticBannerKind kind;
  final String message;

  @override
  Widget build(BuildContext context) {
    final presentation = _presentation(kind);
    return Semantics(
      label: message,
      liveRegion: true,
      container: true,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: presentation.background,
          borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space12),
          child: Row(
            children: [
              Icon(
                presentation.icon,
                color: presentation.foreground,
                size: AppSpacing.iconMedium,
              ),
              const SizedBox(width: AppSpacing.space8),
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.bodyStrong.copyWith(
                    color: presentation.foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

_BannerPresentation _presentation(SemanticBannerKind kind) => switch (kind) {
  SemanticBannerKind.ok => const _BannerPresentation(
    foreground: AppColors.successDark,
    background: AppColors.successBackground,
    icon: Icons.check_circle_outline_rounded,
  ),
  SemanticBannerKind.warning => const _BannerPresentation(
    foreground: AppColors.warning,
    background: AppColors.warningBackground,
    icon: Icons.warning_amber_rounded,
  ),
  SemanticBannerKind.danger => const _BannerPresentation(
    foreground: AppColors.danger,
    background: AppColors.dangerBackground,
    icon: Icons.error_outline_rounded,
  ),
};

class _BannerPresentation {
  const _BannerPresentation({
    required this.foreground,
    required this.background,
    required this.icon,
  });

  final Color foreground;
  final Color background;
  final IconData icon;
}
