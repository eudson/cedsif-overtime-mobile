import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:cedsif_overtime_mobile/core/branding/branding_defaults.dart';

part 'branding_config.freezed.dart';

@freezed
abstract class BrandingConfig with _$BrandingConfig {
  const factory BrandingConfig({
    @Default(BrandingDefaults.appName) String appName,
    @Default(BrandingDefaults.primaryColor) Color primaryColor,
    @Default(BrandingDefaults.secondaryColor) Color secondaryColor,
  }) = _BrandingConfig;
}
