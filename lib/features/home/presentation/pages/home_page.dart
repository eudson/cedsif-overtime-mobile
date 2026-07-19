import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cedsif_overtime_mobile/features/home/presentation/providers/home_provider.dart';
import 'package:cedsif_overtime_mobile/features/home/presentation/widgets/home_content_view.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    unawaited(Future<void>.microtask(_loadInitialContent));
  }

  Future<void> _loadInitialContent() async {
    if (!mounted) {
      return;
    }
    await ref.read(homeNotifierProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeNotifierProvider);

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
