import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cedsif_overtime_mobile/core/constants/constants.dart';
import 'package:cedsif_overtime_mobile/features/auth/presentation/widgets/session_menu_drawer.dart';
import 'package:cedsif_overtime_mobile/features/history/presentation/models/history_entry.dart';
import 'package:cedsif_overtime_mobile/features/history/presentation/pages/history_page.dart';
import 'package:cedsif_overtime_mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:cedsif_overtime_mobile/features/overtime/presentation/providers/overtime_provider.dart';
import 'package:cedsif_overtime_mobile/widgets/status_chip.dart';

class OvertimeHistoryRoute extends ConsumerStatefulWidget {
  const OvertimeHistoryRoute({this.onHomeSelected, super.key});

  final VoidCallback? onHomeSelected;

  @override
  ConsumerState<OvertimeHistoryRoute> createState() =>
      _OvertimeHistoryRouteState();
}

class _OvertimeHistoryRouteState extends ConsumerState<OvertimeHistoryRoute> {
  @override
  void initState() {
    super.initState();
    if (!ref.read(overtimeProvider).isLoaded) {
      unawaited(ref.read(overtimeProvider.notifier).load());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(overtimeProvider);
    return HistoryPage(
      entries: state.isLoaded
          ? state.history.map(_toHistoryEntry).toList()
          : null,
      onHomeSelected: widget.onHomeSelected,
      drawer: SessionMenuDrawer(
        onLoggedOut: () => context.go(RouteConstants.login),
      ),
    );
  }

  HistoryEntry _toHistoryEntry(OvertimeSession session) {
    final endedAt = session.endedAt ?? session.startedAt;
    return HistoryEntry(
      dateLabel:
          '${session.startedAt.day.toString().padLeft(2, '0')} '
          '${'calendar.months.${session.startedAt.month}'.tr()} · '
          '${'calendar.weekdays.${session.startedAt.weekday}'.tr()}',
      startTime: _formatTime(session.startedAt),
      endTime: _formatTime(endedAt),
      duration: _formatDuration(session.durationAt(endedAt)),
      status: switch (session.status) {
        OvertimeSessionStatus.active => AppStatus.emCurso,
        OvertimeSessionStatus.reviewing => AppStatus.emCurso,
        OvertimeSessionStatus.pending => AppStatus.pendente,
        OvertimeSessionStatus.approved => AppStatus.aprovada,
      },
    );
  }

  String _formatTime(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';

  String _formatDuration(Duration value) =>
      '${value.inHours.toString().padLeft(2, '0')}:'
      '${value.inMinutes.remainder(60).toString().padLeft(2, '0')}';
}
