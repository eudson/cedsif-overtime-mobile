import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:cedsif_overtime_mobile/theme/app_colors.dart';
import 'package:cedsif_overtime_mobile/theme/app_spacing.dart';
import 'package:cedsif_overtime_mobile/theme/app_typography.dart';
import 'package:cedsif_overtime_mobile/widgets/app_scaffold.dart';

class HomePage extends StatelessWidget {
  const HomePage({this.onStart, this.onHistorySelected, super.key});

  final VoidCallback? onStart;
  final VoidCallback? onHistorySelected;

  @override
  Widget build(BuildContext context) => AppScaffold(
    showTopBar: true,
    showBottomNavigation: true,
    currentIndex: 0,
    onMenuPressed: () {},
    onDestinationSelected: (index) {
      if (index == 1) {
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
              const _FaeIdentity(),
              const SizedBox(height: AppSpacing.space24),
              const Row(
                children: [
                  Expanded(
                    child: _StatusTile(
                      icon: Icons.circle,
                      labelKey: 'home.insidePerimeter',
                    ),
                  ),
                  SizedBox(width: AppSpacing.space12),
                  Expanded(
                    child: _StatusTile(
                      icon: Icons.cloud_done_outlined,
                      labelKey: 'home.online',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space56),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSpacing.homePromptMaxWidth,
                  ),
                  child: Text(
                    'home.notStarted'.tr(),
                    style: AppTypography.input.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space24),
              Center(child: _StartButton(onPressed: onStart)),
              const SizedBox(height: AppSpacing.space48),
              const _ApprovedHoursCard(),
            ],
          ),
        ),
      ),
    ),
  );
}

class _FaeIdentity extends StatelessWidget {
  const _FaeIdentity();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'home.greeting'.tr(),
        style: AppTypography.input.copyWith(color: AppColors.textSecondary),
      ),
      const SizedBox(height: AppSpacing.space4),
      Text('home.name'.tr(), style: AppTypography.screenTitleLarge),
      const SizedBox(height: AppSpacing.space4),
      Text(
        'home.identity'.tr(),
        style: AppTypography.input.copyWith(color: AppColors.textMuted),
      ),
    ],
  );
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({required this.icon, required this.labelKey});

  final IconData icon;
  final String labelKey;

  @override
  Widget build(BuildContext context) => Semantics(
    label: labelKey.tr(),
    container: true,
    child: SizedBox(
      height: AppSpacing.homeStatusHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.successBackground,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: AppColors.secondary,
                size: icon == Icons.circle
                    ? AppSpacing.space12
                    : AppSpacing.iconMedium,
              ),
              const SizedBox(width: AppSpacing.space8),
              Flexible(
                child: Text(
                  labelKey.tr(),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: AppTypography.labelStrong.copyWith(
                    color: AppColors.successDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _StartButton extends StatelessWidget {
  const _StartButton({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final label = 'home.start'.tr();
    return Semantics(
      button: true,
      label: label,
      child: SizedBox.square(
        key: const ValueKey('home-start-button'),
        dimension: AppSpacing.homeStartSize,
        child: Material(
          color: AppColors.primary,
          elevation: AppSpacing.elevationHero,
          shadowColor: AppColors.successSoft,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed ?? () {},
            customBorder: const CircleBorder(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.play_arrow_rounded,
                  color: AppColors.onPrimary,
                  size: AppSpacing.iconHero,
                ),
                const SizedBox(height: AppSpacing.space8),
                Text(
                  label,
                  style: AppTypography.screenTitle.copyWith(
                    color: AppColors.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ApprovedHoursCard extends StatelessWidget {
  const _ApprovedHoursCard();

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        '${'home.approvedHours'.tr()}, ${'home.approvedTotal'.tr()}, '
        '${'home.thisMonth'.tr()}',
    container: true,
    child: ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: AppSpacing.homeSummaryMinHeight,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.warningBackground,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'home.thisMonth'.tr(),
                      style: AppTypography.labelStrong.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    Text(
                      'home.approvedHours'.tr(),
                      style: AppTypography.sectionTitle.copyWith(
                        color: AppColors.textStrong,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.space16),
              Text(
                'home.approvedTotal'.tr(),
                style: AppTypography.numericTotal,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
