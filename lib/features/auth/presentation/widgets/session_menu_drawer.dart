import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cedsif_overtime_mobile/features/auth/presentation/providers/login_provider.dart';
import 'package:cedsif_overtime_mobile/theme/app_colors.dart';
import 'package:cedsif_overtime_mobile/theme/app_spacing.dart';
import 'package:cedsif_overtime_mobile/theme/app_typography.dart';
import 'package:cedsif_overtime_mobile/widgets/app_button.dart';

class SessionMenuDrawer extends ConsumerWidget {
  const SessionMenuDrawer({required this.onLoggedOut, super.key});

  final VoidCallback onLoggedOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(logoutNotifierProvider);
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.space24),
              child: Text(
                'navigation.menu'.tr(),
                style: AppTypography.screenTitle,
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.space16),
              child: TextButton(
                style: ButtonStyle(
                  alignment: Alignment.centerLeft,
                  animationDuration: AppSpacing.menuInteractionDuration,
                  minimumSize: const WidgetStatePropertyAll(
                    Size.fromHeight(AppSpacing.touchTarget),
                  ),
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: AppSpacing.space16),
                  ),
                  foregroundColor: const WidgetStatePropertyAll(
                    AppColors.danger,
                  ),
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.hovered) ||
                        states.contains(WidgetState.focused) ||
                        states.contains(WidgetState.pressed)) {
                      return AppColors.dangerBackground;
                    }
                    return AppColors.transparent;
                  }),
                  overlayColor: const WidgetStatePropertyAll(
                    AppColors.transparent,
                  ),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusCard,
                      ),
                    ),
                  ),
                  textStyle: const WidgetStatePropertyAll(
                    AppTypography.labelStrong,
                  ),
                ),
                onPressed: state.isLoading
                    ? null
                    : () => _confirmLogout(context, ref),
                child: Row(
                  children: [
                    if (state.isLoading)
                      const SizedBox.square(
                        dimension: AppSpacing.iconMedium,
                        child: CircularProgressIndicator(
                          color: AppColors.danger,
                          strokeWidth: AppSpacing.progressStrokeWidth,
                        ),
                      )
                    else
                      const Icon(Icons.logout_rounded),
                    const SizedBox(width: AppSpacing.space16),
                    Expanded(
                      child: Text(
                        'auth.logout'.tr(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('auth.logoutConfirmTitle'.tr()),
        content: Text('auth.logoutConfirmMessage'.tr()),
        actions: [
          SizedBox(
            width: double.maxFinite,
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'common.cancel'.tr(),
                    variant: AppButtonVariant.secondary,
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                  ),
                ),
                const SizedBox(width: AppSpacing.space12),
                Expanded(
                  child: AppButton(
                    label: 'auth.continue'.tr(),
                    variant: AppButtonVariant.destructive,
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    final errorMessage = 'errors.generic'.tr();
    Navigator.of(context).pop();
    final succeeded = await ref.read(logoutNotifierProvider.notifier).logout();
    if (succeeded) {
      onLoggedOut();
    } else {
      messenger?.showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }
}
