import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:cedsif_overtime_mobile/features/history/presentation/models/history_entry.dart';
import 'package:cedsif_overtime_mobile/theme/app_colors.dart';
import 'package:cedsif_overtime_mobile/theme/app_spacing.dart';
import 'package:cedsif_overtime_mobile/theme/app_typography.dart';
import 'package:cedsif_overtime_mobile/widgets/status_chip.dart';

class HistoryEntryCard extends StatelessWidget {
  const HistoryEntryCard({required this.entry, super.key});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final statusLabel = switch (entry.status) {
      AppStatus.pendente => 'status.pending'.tr(),
      AppStatus.aprovada => 'status.approved'.tr(),
      AppStatus.emCurso => 'status.inProgress'.tr(),
      AppStatus.bloqueado => 'status.blocked'.tr(),
      AppStatus.offline => 'status.offline'.tr(),
    };
    final timeLabel =
        '${entry.startTime} → ${entry.endTime} · ${entry.duration}';

    return Semantics(
      container: true,
      label: '${entry.dateLabel}, $timeLabel, $statusLabel',
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppSpacing.historyCardMinHeight,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final details = Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.dateLabel, style: AppTypography.sectionTitle),
                    const SizedBox(height: AppSpacing.space4),
                    Text(timeLabel, style: AppTypography.historyTime),
                  ],
                );
                final chip = StatusChip(status: entry.status);

                if (constraints.maxWidth <
                    AppSpacing.historyCardRowBreakpoint) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      details,
                      const SizedBox(height: AppSpacing.space12),
                      Align(alignment: Alignment.centerRight, child: chip),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: details),
                    const SizedBox(width: AppSpacing.space12),
                    chip,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
