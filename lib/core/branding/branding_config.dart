import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:cedsif_overtime_mobile/core/branding/branding_defaults.dart';

part 'branding_config.freezed.dart';

@freezed
abstract class BrandingConfig with _$BrandingConfig {
  const factory BrandingConfig({
    @Default(BrandingDefaults.appNameKey) String appNameKey,
    @Default(BrandingDefaults.primaryColorArgb) int primaryColorArgb,
    @Default(BrandingDefaults.secondaryColorArgb) int secondaryColorArgb,
  }) = _BrandingConfig;
}
