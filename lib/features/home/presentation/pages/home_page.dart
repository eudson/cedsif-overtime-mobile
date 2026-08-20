import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:cedsif_overtime_mobile/theme/app_colors.dart';
import 'package:cedsif_overtime_mobile/theme/app_spacing.dart';
import 'package:cedsif_overtime_mobile/theme/app_typography.dart';
import 'package:cedsif_overtime_mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:cedsif_overtime_mobile/features/profile/domain/entities/employee_profile.dart';
import 'package:cedsif_overtime_mobile/widgets/app_button.dart';
import 'package:cedsif_overtime_mobile/widgets/app_scaffold.dart';
import 'package:cedsif_overtime_mobile/widgets/semantic_banner.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    this.onStart,
    this.onStop,
    this.onHistorySelected,
    this.onProfileSelected,
    this.profile,
    this.activeSession,
    this.elapsed = Duration.zero,
    this.isBusy = false,
    this.errorMessage,
    this.drawer,
    super.key,
  });

  final VoidCallback? onStart;
  final VoidCallback? onStop;
  final VoidCallback? onHistorySelected;
  final VoidCallback? onProfileSelected;
  final EmployeeProfile? profile;
  final OvertimeSession? activeSession;
  final Duration elapsed;
  final bool isBusy;
  final String? errorMessage;
  final Widget? drawer;

  @override
  Widget build(BuildContext context) {
    final running = activeSession != null;
    return AppScaffold(
      showTopBar: true,
      showBottomNavigation: !running,
      currentIndex: 0,
      drawer: drawer,
      onDestinationSelected: (index) {
        if (index == 1) {
          onHistorySelected?.call();
        } else if (index == 2) {
          onProfileSelected?.call();
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
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.pageMaxWidth,
            ),
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
                if (running)
                  _RunningContent(
                    activeSession: activeSession!,
                    elapsed: elapsed,
                    isBusy: isBusy,
                    onStop: onStop,
                    employeeName: profile?.fullName,
                  )
                else ...[
                  _FaeIdentity(profile: profile),
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
                  Center(
                    child: _StartButton(onPressed: isBusy ? null : onStart),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RunningContent extends StatelessWidget {
  const _RunningContent({
    required this.activeSession,
    required this.elapsed,
    required this.isBusy,
    this.onStop,
    this.employeeName,
  });

  final OvertimeSession activeSession;
  final Duration elapsed;
  final bool isBusy;
  final VoidCallback? onStop;
  final String? employeeName;

  @override
  Widget build(BuildContext context) {
    final progress = (elapsed.inSeconds / const Duration(hours: 4).inSeconds)
        .clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.location_on_outlined, color: AppColors.secondary),
            const SizedBox(width: AppSpacing.space8),
            Expanded(
              child: Text(
                'home.insidePerimeterRunning'.tr(),
                style: AppTypography.bodyStrong,
              ),
            ),
            const _OnlineChip(),
          ],
        ),
        const SizedBox(height: AppSpacing.space48),
        Center(
          child: SizedBox.square(
            key: const ValueKey('home-running-timer-circle'),
            dimension: AppSpacing.runningTimerSize,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: AppSpacing.runningTimerStroke,
                  backgroundColor: AppColors.border,
                  color: AppColors.secondary,
                  strokeCap: StrokeCap.butt,
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'home.inProgress'.tr(),
                      style: AppTypography.labelStrong.copyWith(
                        color: AppColors.successDark,
                        letterSpacing: AppSpacing.space2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space16),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.runningTimerHorizontalInset,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _formatDuration(elapsed),
                            key: const ValueKey('home-running-timer'),
                            style: AppTypography.timerLarge,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space8),
                    Text(
                      'home.plannedDuration'.tr(),
                      style: AppTypography.body,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space24),
        Text(
          'home.startedAt'.tr(
            namedArgs: {
              'time': _formatTime(activeSession.startedAt),
              'name': employeeName ?? '',
            },
          ),
          textAlign: TextAlign.center,
          style: AppTypography.body,
        ),
        const SizedBox(height: AppSpacing.space56),
        AppButton(
          label: 'home.stop'.tr(),
          onPressed: isBusy ? null : onStop,
          isLoading: isBusy,
          leadingIcon: Icons.stop_circle_outlined,
          variant: AppButtonVariant.destructive,
        ),
        const SizedBox(height: AppSpacing.space16),
        Text(
          'home.submitAfterStop'.tr(),
          textAlign: TextAlign.center,
          style: AppTypography.body.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }

  static String _formatDuration(Duration duration) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(duration.inHours)}:'
        '${two(duration.inMinutes.remainder(60))}:'
        '${two(duration.inSeconds.remainder(60))}';
  }

  static String _formatTime(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}

class _OnlineChip extends StatelessWidget {
  const _OnlineChip();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.successBackground,
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space16,
        vertical: AppSpacing.space12,
      ),
      child: Text(
        'home.onlineUpper'.tr(),
        style: AppTypography.labelStrong.copyWith(color: AppColors.successDark),
      ),
    ),
  );
}

class _FaeIdentity extends StatelessWidget {
  const _FaeIdentity({this.profile});

  final EmployeeProfile? profile;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'home.greeting'.tr(),
        style: AppTypography.input.copyWith(color: AppColors.textSecondary),
      ),
      const SizedBox(height: AppSpacing.space4),
      Text(profile?.fullName ?? '', style: AppTypography.screenTitleLarge),
      const SizedBox(height: AppSpacing.space4),
      Text(switch (profile) {
        null => '',
        final employee when employee.workUnit == null => 'home.identity'.tr(
          namedArgs: {'nuit': employee.nuit},
        ),
        final employee => 'home.identityWithWorkUnit'.tr(
          namedArgs: {
            'nuit': employee.nuit,
            'workUnit': employee.workUnit!.name,
          },
        ),
      }, style: AppTypography.input.copyWith(color: AppColors.textMuted)),
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
