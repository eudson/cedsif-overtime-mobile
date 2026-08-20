import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cedsif_overtime_mobile/core/constants/constants.dart';
import 'package:cedsif_overtime_mobile/features/auth/presentation/widgets/session_menu_drawer.dart';
import 'package:cedsif_overtime_mobile/features/profile/presentation/pages/profile_page.dart';
import 'package:cedsif_overtime_mobile/features/profile/presentation/providers/profile_provider.dart';

class ProfileRoute extends ConsumerStatefulWidget {
  const ProfileRoute({this.onHomeSelected, this.onHistorySelected, super.key});

  final VoidCallback? onHomeSelected;
  final VoidCallback? onHistorySelected;

  @override
  ConsumerState<ProfileRoute> createState() => _ProfileRouteState();
}

class _ProfileRouteState extends ConsumerState<ProfileRoute> {
  @override
  void initState() {
    super.initState();
    if (ref.read(profileProvider).profile == null) {
      unawaited(Future.microtask(ref.read(profileProvider.notifier).load));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    return ProfilePage(
      profile: state.profile,
      isLoading: state.isLoading,
      errorMessage: state.errorKey?.tr(),
      onRetry: ref.read(profileProvider.notifier).load,
      onHomeSelected: widget.onHomeSelected,
      onHistorySelected: widget.onHistorySelected,
      drawer: SessionMenuDrawer(
        onLoggedOut: () => context.go(RouteConstants.login),
      ),
    );
  }
}
