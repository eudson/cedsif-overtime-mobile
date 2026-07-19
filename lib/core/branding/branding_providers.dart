import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cedsif_overtime_mobile/core/branding/branding_config.dart';
import 'package:cedsif_overtime_mobile/core/branding/tenant_theme_builder.dart';

final brandingConfigProvider = Provider<BrandingConfig>(
  (ref) => const BrandingConfig(),
);

final lightThemeProvider = Provider<ThemeData>(
  (ref) => TenantThemeBuilder.light(ref.watch(brandingConfigProvider)),
);

final darkThemeProvider = Provider<ThemeData>(
  (ref) => TenantThemeBuilder.dark(ref.watch(brandingConfigProvider)),
);
