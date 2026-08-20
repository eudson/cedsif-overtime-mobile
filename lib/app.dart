import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cedsif_overtime_mobile/core/branding/branding_providers.dart';
import 'package:cedsif_overtime_mobile/core/auth/session_scope.dart';
import 'package:cedsif_overtime_mobile/core/config/providers.dart';
import 'package:cedsif_overtime_mobile/core/config/router.dart';
import 'package:cedsif_overtime_mobile/core/constants/constants.dart';
import 'package:cedsif_overtime_mobile/core/network/auth_event_bus.dart';

class HorasExtrasApp extends ConsumerStatefulWidget {
  const HorasExtrasApp({super.key});

  @override
  ConsumerState<HorasExtrasApp> createState() => _HorasExtrasAppState();
}

class _HorasExtrasAppState extends ConsumerState<HorasExtrasApp> {
  StreamSubscription<AuthEvent>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = ref
        .read(authEventBusProvider)
        .events
        .listen(_handleAuthEvent);
  }

  void _handleAuthEvent(AuthEvent event) {
    if (!mounted || event != AuthEvent.sessionExpired) {
      return;
    }
    ref.read(sessionEpochProvider.notifier).advance();
    ref.read(routerProvider).go(RouteConstants.splash);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingConfigProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (_) => branding.appNameKey.tr(),
      theme: ref.watch(lightThemeProvider),
      darkTheme: ref.watch(darkThemeProvider),
      routerConfig: ref.watch(routerProvider),
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
    );
  }
}
