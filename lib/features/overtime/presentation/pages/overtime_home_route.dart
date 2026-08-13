import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cedsif_overtime_mobile/features/home/presentation/pages/home_page.dart';
import 'package:cedsif_overtime_mobile/features/overtime/presentation/providers/overtime_provider.dart';

class OvertimeHomeRoute extends ConsumerStatefulWidget {
  const OvertimeHomeRoute({this.onHistorySelected, super.key});

  final VoidCallback? onHistorySelected;

  @override
  ConsumerState<OvertimeHomeRoute> createState() => _OvertimeHomeRouteState();
}

class _OvertimeHomeRouteState extends ConsumerState<OvertimeHomeRoute> {
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
    return HomePage(
      activeSession: state.activeSession,
      elapsed: state.elapsed,
      isBusy: state.isSaving,
      errorMessage: state.errorKey?.tr(),
      onStart: ref.read(overtimeProvider.notifier).start,
      onStop: ref.read(overtimeProvider.notifier).stop,
      onHistorySelected: widget.onHistorySelected,
    );
  }
}
