import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:cedsif_overtime_mobile/features/history/presentation/models/history_entry.dart';
import 'package:cedsif_overtime_mobile/features/history/presentation/widgets/history_entry_card.dart';
import 'package:cedsif_overtime_mobile/theme/app_colors.dart';
import 'package:cedsif_overtime_mobile/theme/app_spacing.dart';
import 'package:cedsif_overtime_mobile/theme/app_typography.dart';
import 'package:cedsif_overtime_mobile/widgets/app_scaffold.dart';
import 'package:cedsif_overtime_mobile/widgets/status_chip.dart';

const defaultHistoryEntries = <HistoryEntry>[
  HistoryEntry(
    dateLabel: '18 Jul · Sex',
    startTime: '08:24',
    endTime: '11:11',
    duration: '02:47',
    status: AppStatus.pendente,
  ),
  HistoryEntry(
    dateLabel: '15 Jul · Ter',
    startTime: '17:00',
    endTime: '21:06',
    duration: '04:06',
    status: AppStatus.aprovada,
  ),
  HistoryEntry(
    dateLabel: '11 Jul · Sex',
    startTime: '18:00',
    endTime: '22:24',
    duration: '04:24',
    status: AppStatus.aprovada,
  ),
  HistoryEntry(
    dateLabel: '08 Jul · Ter',
    startTime: '18:30',
    endTime: '21:00',
    duration: '02:30',
    status: AppStatus.aprovada,
  ),
];

class HistoryPage extends StatelessWidget {
  const HistoryPage({
    this.entries,
    this.onHomeSelected,
    this.onHistorySelected,
    super.key,
  });

  final List<HistoryEntry>? entries;
  final VoidCallback? onHomeSelected;
  final VoidCallback? onHistorySelected;

  @override
  Widget build(BuildContext context) {
    final visibleEntries = entries ?? defaultHistoryEntries;

    return AppScaffold(
      showTopBar: true,
      showBottomNavigation: true,
      currentIndex: 1,
      onMenuPressed: () {},
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            onHomeSelected?.call();
          case 1:
            onHistorySelected?.call();
          case 2:
            break;
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
                    for (
                      var index = 0;
                      index < visibleEntries.length;
                      index++
                    ) ...[
                      HistoryEntryCard(entry: visibleEntries[index]),
                      if (index < visibleEntries.length - 1)
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
