import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:cedsif_overtime_mobile/core/constants/app_text_styles.dart';
import 'package:cedsif_overtime_mobile/core/widgets/empty_state_widget.dart';
import 'package:cedsif_overtime_mobile/features/home/presentation/providers/home_provider.dart';

class HomeContentView extends StatelessWidget {
  const HomeContentView({
    required this.state,
    required this.onRetry,
    super.key,
  });

  final HomeState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorKey case final errorKey?) {
      return EmptyStateWidget(
        icon: Icons.error_outline,
        title: errorKey.tr(),
        actionLabel: 'common.retry'.tr(),
        onAction: onRetry,
      );
    }

    if (state.content case final content?) {
      return Center(
        child: Text(
          content.translationKey.tr(),
          style: AppTextStyles.headline,
          textAlign: TextAlign.center,
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
