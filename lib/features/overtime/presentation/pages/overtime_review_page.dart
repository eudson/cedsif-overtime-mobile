import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:cedsif_overtime_mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:cedsif_overtime_mobile/theme/app_colors.dart';
import 'package:cedsif_overtime_mobile/theme/app_spacing.dart';
import 'package:cedsif_overtime_mobile/theme/app_typography.dart';
import 'package:cedsif_overtime_mobile/widgets/app_button.dart';
import 'package:cedsif_overtime_mobile/widgets/app_scaffold.dart';
import 'package:cedsif_overtime_mobile/widgets/semantic_banner.dart';

class OvertimeReviewPage extends StatelessWidget {
  const OvertimeReviewPage({
    required this.session,
    required this.elapsed,
    this.onSubmit,
    this.onResume,
    this.onMenuPressed,
    this.drawer,
    this.isBusy = false,
    this.errorMessage,
    super.key,
  });

  final OvertimeSession session;
  final Duration elapsed;
  final VoidCallback? onSubmit;
  final VoidCallback? onResume;
  final VoidCallback? onMenuPressed;
  final Widget? drawer;
  final bool isBusy;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) => AppScaffold(
    showTopBar: true,
    onMenuPressed: onMenuPressed,
    drawer: drawer,
    backgroundColor: AppColors.surfaceAlternative,
    body: LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.space16),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: AppSpacing.pageMaxWidth,
              minHeight: constraints.maxHeight - (AppSpacing.space16 * 2),
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (errorMessage case final message?) ...[
                    SemanticBanner(
                      kind: SemanticBannerKind.danger,
                      message: message,
                    ),
                    const SizedBox(height: AppSpacing.space16),
                  ],
                  const Spacer(),
                  Text(
                    'overtimeReview.title'.tr(),
                    textAlign: TextAlign.center,
                    style: AppTypography.screenTitleLarge,
                  ),
                  const SizedBox(height: AppSpacing.space12),
                  Text(
                    'overtimeReview.subtitle'.tr(),
                    textAlign: TextAlign.center,
                    style: AppTypography.body,
                  ),
                  const SizedBox(height: AppSpacing.space24),
                  _ReviewSummaryCard(session: session, elapsed: elapsed),
                  const Spacer(),
                  AppButton(
                    label: 'overtimeReview.submit'.tr(),
                    leadingIcon: Icons.send_rounded,
                    isLoading: isBusy,
                    onPressed: isBusy ? null : onSubmit,
                  ),
                  const SizedBox(height: AppSpacing.space12),
                  AppButton(
                    label: 'overtimeReview.resume'.tr(),
                    leadingIcon: Icons.play_arrow_rounded,
                    variant: AppButtonVariant.secondary,
                    onPressed: isBusy ? null : onResume,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _ReviewSummaryCard extends StatelessWidget {
  const _ReviewSummaryCard({required this.session, required this.elapsed});

  final OvertimeSession session;
  final Duration elapsed;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.canvas,
      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
    ),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.space20),
      child: Column(
        children: [
          _SummaryRow(
            icon: Icons.login_rounded,
            label: 'overtimeReview.start'.tr(),
            value: _formatTime(session.startedAt),
          ),
          const Divider(height: AppSpacing.space24, color: AppColors.border),
          _SummaryRow(
            icon: Icons.logout_rounded,
            label: 'overtimeReview.end'.tr(),
            value: _formatTime(session.endedAt ?? session.startedAt),
          ),
          const Divider(height: AppSpacing.space24, color: AppColors.border),
          Row(
            children: [
              Expanded(
                child: Text(
                  'overtimeReview.registeredTime'.tr(),
                  style: AppTypography.sectionTitle.copyWith(
                    color: AppColors.successDark,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space12),
              Text(_formatDuration(elapsed), style: AppTypography.numericTotal),
            ],
          ),
        ],
      ),
    ),
  );

  static String _formatTime(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';

  static String _formatDuration(Duration duration) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(duration.inHours)}:'
        '${two(duration.inMinutes.remainder(60))}:'
        '${two(duration.inSeconds.remainder(60))}';
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: AppColors.primary, size: AppSpacing.iconMedium),
      const SizedBox(width: AppSpacing.space12),
      Expanded(child: Text(label, style: AppTypography.body)),
      const SizedBox(width: AppSpacing.space12),
      Text(value, style: AppTypography.reviewTime),
    ],
  );
}
