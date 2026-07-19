import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cedsif_overtime_mobile/features/home/presentation/providers/home_provider.dart';
import 'package:cedsif_overtime_mobile/features/home/presentation/widgets/home_content_view.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeNotifierProvider);
    if (!state.isLoading && state.content == null && state.errorKey == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(homeNotifierProvider.notifier).load();
      });
    }

    return Scaffold(
      body: SafeArea(
        child: HomeContentView(
          state: state,
          onRetry: () => ref.read(homeNotifierProvider.notifier).load(),
        ),
      ),
    );
  }
}
