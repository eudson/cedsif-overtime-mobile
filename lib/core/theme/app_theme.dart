import 'package:flutter/material.dart';

import 'package:cedsif_overtime_mobile/core/branding/branding_config.dart';
import 'package:cedsif_overtime_mobile/core/branding/tenant_theme_builder.dart';

abstract final class AppTheme {
  static final ThemeData light = TenantThemeBuilder.light(
    const BrandingConfig(),
  );
  static final ThemeData dark = TenantThemeBuilder.dark(const BrandingConfig());
}
