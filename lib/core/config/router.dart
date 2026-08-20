import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cedsif_overtime_mobile/core/constants/constants.dart';
import 'package:cedsif_overtime_mobile/features/auth/presentation/pages/facial_validation_stub_page.dart';
import 'package:cedsif_overtime_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:cedsif_overtime_mobile/features/auth/presentation/providers/login_provider.dart';
import 'package:cedsif_overtime_mobile/features/overtime/presentation/pages/overtime_history_route.dart';
import 'package:cedsif_overtime_mobile/features/overtime/presentation/pages/overtime_home_route.dart';

typedef SessionValidator = Future<bool> Function();

final class SessionExpiryRefresh extends ChangeNotifier {
  SessionExpiryRefresh({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  Timer? _timer;
  DateTime? _scheduledExpiry;

  void schedule(DateTime? expiry) {
    if (_scheduledExpiry == expiry && _timer?.isActive == true) {
      return;
    }
    _timer?.cancel();
    _scheduledExpiry = expiry;
    if (expiry == null) {
      return;
    }
    final delay = expiry.difference(_now().toUtc());
    _timer = Timer(delay.isNegative ? Duration.zero : delay, notifyListeners);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

Future<String?> appRedirect(
  BuildContext? context,
  GoRouterState state, {
  required SessionValidator hasValidSession,
}) async {
  final path = state.uri.path;
  if (path == RouteConstants.splash) {
    return null;
  }

  final isAuthenticated = await hasValidSession();
  if (!isAuthenticated) {
    return path == RouteConstants.login ? null : RouteConstants.login;
  }
  return path == RouteConstants.login ? RouteConstants.facialValidation : null;
}

GoRouter createAppRouter({
  String initialLocation = RouteConstants.splash,
  SessionValidator? hasValidSession,
  Listenable? sessionRefresh,
}) {
  final validateSession = hasValidSession ?? () async => false;
  return GoRouter(
    initialLocation: initialLocation,
    redirect: (context, state) =>
        appRedirect(context, state, hasValidSession: validateSession),
    refreshListenable: sessionRefresh,
    routes: <RouteBase>[
      GoRoute(
        path: RouteConstants.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: RouteConstants.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RouteConstants.facialValidation,
        builder: (context, state) => const FacialValidationStubPage(),
      ),
      GoRoute(
        path: RouteConstants.home,
        builder: (context, state) => OvertimeHomeRoute(
          onHistorySelected: () => context.go(RouteConstants.history),
        ),
      ),
      GoRoute(
        path: RouteConstants.history,
        builder: (context, state) => OvertimeHistoryRoute(
          onHomeSelected: () => context.go(RouteConstants.home),
        ),
      ),
    ],
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final sessionService = ref.watch(authSessionServiceProvider);
  final sessionRefresh = SessionExpiryRefresh();
  Future<bool> validateSession() async {
    final expiry = await sessionService.validUntil();
    sessionRefresh.schedule(expiry);
    return expiry != null;
  }

  final router = createAppRouter(
    hasValidSession: validateSession,
    sessionRefresh: sessionRefresh,
  );
  ref.onDispose(() {
    router.dispose();
    sessionRefresh.dispose();
  });
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
      context.go(RouteConstants.login);
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
