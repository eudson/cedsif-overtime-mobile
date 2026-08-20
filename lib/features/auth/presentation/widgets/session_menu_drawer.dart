import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cedsif_overtime_mobile/features/auth/presentation/providers/login_provider.dart';
import 'package:cedsif_overtime_mobile/theme/app_colors.dart';
import 'package:cedsif_overtime_mobile/theme/app_spacing.dart';
import 'package:cedsif_overtime_mobile/theme/app_typography.dart';

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
            ListTile(
              minTileHeight: AppSpacing.touchTarget,
              leading: state.isLoading
                  ? const SizedBox.square(
                      dimension: AppSpacing.iconMedium,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout_rounded),
              title: Text('auth.logout'.tr()),
              enabled: !state.isLoading,
              onTap: state.isLoading
                  ? null
                  : () => _confirmLogout(context, ref),
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
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('common.confirm'.tr()),
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
