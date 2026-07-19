import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cedsif_overtime_mobile/core/constants/constants.dart';
import 'package:cedsif_overtime_mobile/features/home/presentation/pages/home_page.dart';

String? appRedirect(BuildContext? context, GoRouterState state) => null;

GoRouter createAppRouter({String initialLocation = RouteConstants.splash}) =>
    GoRouter(
      initialLocation: initialLocation,
      redirect: appRedirect,
      routes: <RouteBase>[
        GoRoute(
          path: RouteConstants.splash,
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: RouteConstants.home,
          builder: (context, state) => const HomePage(),
        ),
      ],
    );

final routerProvider = Provider<GoRouter>((ref) {
  final router = createAppRouter();
  ref.onDispose(router.dispose);
  return router;
});

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(AppConstants.splashDuration, _openHome);
  }

  void _openHome() {
    if (mounted) {
      context.go(RouteConstants.home);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
