import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:cedsif_overtime_mobile/features/history/presentation/models/history_entry.dart';
import 'package:cedsif_overtime_mobile/features/history/presentation/widgets/history_entry_card.dart';
import 'package:cedsif_overtime_mobile/theme/app_colors.dart';
import 'package:cedsif_overtime_mobile/theme/app_spacing.dart';
import 'package:cedsif_overtime_mobile/theme/app_typography.dart';
import 'package:cedsif_overtime_mobile/widgets/app_scaffold.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({
    this.entries = const [],
    this.isLoading = false,
    this.onHomeSelected,
    this.onHistorySelected,
    this.onProfileSelected,
    this.drawer,
    super.key,
  });

  final List<HistoryEntry> entries;
  final bool isLoading;
  final VoidCallback? onHomeSelected;
  final VoidCallback? onHistorySelected;
  final VoidCallback? onProfileSelected;
  final Widget? drawer;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showTopBar: true,
      showBottomNavigation: true,
      currentIndex: 1,
      drawer: drawer,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            onHomeSelected?.call();
          case 1:
            onHistorySelected?.call();
          case 2:
            onProfileSelected?.call();
        }
      },
      backgroundColor: AppColors.surfaceAlternative,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.pageMaxWidth),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.space16,
                  AppSpacing.space24,
                  AppSpacing.space16,
                  AppSpacing.space32,
                ),
                sliver: SliverList.list(
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        'history.title'.tr(),
                        style: AppTypography.screenTitleLarge,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space24),
                    if (isLoading)
                      const Center(child: CircularProgressIndicator()),
                    for (var index = 0; index < entries.length; index++) ...[
                      HistoryEntryCard(entry: entries[index]),
                      if (index < entries.length - 1)
                        const SizedBox(height: AppSpacing.space12),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
