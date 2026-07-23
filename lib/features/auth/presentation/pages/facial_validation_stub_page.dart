import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cedsif_overtime_mobile/core/constants/constants.dart';
import 'package:cedsif_overtime_mobile/theme/app_colors.dart';
import 'package:cedsif_overtime_mobile/theme/app_spacing.dart';
import 'package:cedsif_overtime_mobile/theme/app_typography.dart';
import 'package:cedsif_overtime_mobile/widgets/app_button.dart';
import 'package:cedsif_overtime_mobile/widgets/app_scaffold.dart';

class FacialValidationStubPage extends StatelessWidget {
  const FacialValidationStubPage({this.onValidated, super.key});

  final VoidCallback? onValidated;

  @override
  Widget build(BuildContext context) => AppScaffold(
    backgroundColor: AppColors.canvas,
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.pageMaxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.face_rounded,
                size: AppSpacing.iconHero,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.space24),
              Text(
                'auth.facialValidation'.tr(),
                style: AppTypography.screenTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.space40),
              AppButton(
                label: 'auth.continue'.tr(),
                leadingIcon: Icons.arrow_forward_rounded,
                onPressed: onValidated ?? () => context.go(RouteConstants.home),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
