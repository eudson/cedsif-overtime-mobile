import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:cedsif_overtime_mobile/features/profile/domain/entities/employee_profile.dart';
import 'package:cedsif_overtime_mobile/theme/app_colors.dart';
import 'package:cedsif_overtime_mobile/theme/app_spacing.dart';
import 'package:cedsif_overtime_mobile/theme/app_typography.dart';
import 'package:cedsif_overtime_mobile/widgets/app_scaffold.dart';
import 'package:cedsif_overtime_mobile/widgets/semantic_banner.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    this.profile,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.onHomeSelected,
    this.onHistorySelected,
    this.drawer,
    super.key,
  });

  final EmployeeProfile? profile;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onHomeSelected;
  final VoidCallback? onHistorySelected;
  final Widget? drawer;

  @override
  Widget build(BuildContext context) => AppScaffold(
    showTopBar: true,
    showBottomNavigation: true,
    currentIndex: 2,
    drawer: drawer,
    onDestinationSelected: (index) {
      if (index == 0) {
        onHomeSelected?.call();
      } else if (index == 1) {
        onHistorySelected?.call();
      }
    },
    backgroundColor: AppColors.surfaceAlternative,
    body: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space16,
        AppSpacing.space24,
        AppSpacing.space16,
        AppSpacing.space32,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.pageMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('profile.title'.tr(), style: AppTypography.screenTitleLarge),
              const SizedBox(height: AppSpacing.space24),
              if (errorMessage case final message?) ...[
                SemanticBanner(
                  kind: SemanticBannerKind.danger,
                  message: message,
                ),
                const SizedBox(height: AppSpacing.space16),
              ],
              if (isLoading && profile == null)
                const Center(child: CircularProgressIndicator())
              else if (profile case final employee?)
                _ProfileContent(profile: employee)
              else
                Center(
                  child: TextButton(
                    onPressed: onRetry,
                    child: Text('common.retry'.tr()),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.profile});

  final EmployeeProfile profile;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        padding: const EdgeInsets.all(AppSpacing.space24),
        decoration: BoxDecoration(
          color: AppColors.canvas,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        ),
        child: Column(
          children: [
            const CircleAvatar(
              radius: AppSpacing.space40,
              backgroundColor: AppColors.successBackground,
              child: Icon(
                Icons.person_outline_rounded,
                size: AppSpacing.iconLarge,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.space16),
            Text(
              profile.fullName,
              textAlign: TextAlign.center,
              style: AppTypography.screenTitle,
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.space16),
      _DetailCard(
        children: [
          _DetailRow(label: 'profile.nuit'.tr(), value: profile.nuit),
          _DetailRow(
            label: 'profile.workUnit'.tr(),
            value: profile.workUnit?.name ?? 'profile.unassigned'.tr(),
          ),
          if (profile.workUnit case final workUnit?)
            _DetailRow(
              label: 'profile.workUnitReference'.tr(),
              value: workUnit.externalReference,
            ),
        ],
      ),
    ],
  );
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.space20),
    decoration: BoxDecoration(
      color: AppColors.canvas,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index < children.length - 1) const Divider(),
        ],
      ],
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.space8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.small),
        const SizedBox(height: AppSpacing.space4),
        Text(value, style: AppTypography.bodyStrong),
      ],
    ),
  );
}
