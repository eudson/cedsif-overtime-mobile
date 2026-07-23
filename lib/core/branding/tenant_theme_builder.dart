import 'package:flutter/material.dart';

import 'package:cedsif_overtime_mobile/core/branding/branding_config.dart';
import 'package:cedsif_overtime_mobile/theme/app_theme.dart';

abstract final class TenantThemeBuilder {
  static ThemeData light(BrandingConfig branding) => AppTheme.lightFor(
    primary: Color(branding.primaryColorArgb),
    secondary: Color(branding.secondaryColorArgb),
  );

  static ThemeData dark(BrandingConfig branding) => AppTheme.darkFor(
    primary: Color(branding.primaryColorArgb),
    secondary: Color(branding.secondaryColorArgb),
  );
}
