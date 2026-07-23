import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cedsif_overtime_mobile/theme/app_colors.dart';
import 'package:cedsif_overtime_mobile/theme/app_spacing.dart';
import 'package:cedsif_overtime_mobile/theme/app_typography.dart';

void main() {
  test('exposes the approved Portal do FAE colour palette', () {
    expect(AppColors.primary, const Color(0xFF147A52));
    expect(AppColors.secondary, const Color(0xFF1F9D63));
    expect(AppColors.success, const Color(0xFF2E9E5B));
    expect(AppColors.successBackground, const Color(0xFFDFF0E7));
    expect(AppColors.successSoft, const Color(0xFFCDE3D6));
    expect(AppColors.successDark, const Color(0xFF0F6A46));
    expect(AppColors.warning, const Color(0xFFC77700));
    expect(AppColors.warningBackground, const Color(0xFFFDEFC4));
    expect(AppColors.danger, const Color(0xFFC0392B));
    expect(AppColors.dangerBackground, const Color(0xFFFBEDEB));
    expect(AppColors.background, const Color(0xFFF4F6FA));
    expect(AppColors.surface, const Color(0xFFEEF1F5));
    expect(AppColors.surfaceAlternative, const Color(0xFFEDF0F4));
    expect(AppColors.border, const Color(0xFFDDE3EC));
    expect(AppColors.textPrimary, const Color(0xFF1E2531));
    expect(AppColors.textStrong, const Color(0xFF0B1220));
    expect(AppColors.textSecondary, const Color(0xFF6E7681));
    expect(AppColors.textMuted, const Color(0xFF8A94A2));
    expect(AppColors.onPrimary, Colors.white);
  });

  test('uses the approved spacing, shape, and touch target scale', () {
    expect(AppSpacing.space4, 4);
    expect(AppSpacing.space8, 8);
    expect(AppSpacing.space12, 12);
    expect(AppSpacing.space16, 16);
    expect(AppSpacing.space24, 24);
    expect(AppSpacing.radiusCard, 16);
    expect(AppSpacing.radiusInput, 14);
    expect(AppSpacing.radiusChip, 12);
    expect(AppSpacing.radiusPill, 999);
    expect(AppSpacing.buttonHeight, 56);
    expect(AppSpacing.touchTarget, 56);
  });

  test('maps semantic typography to the bundled font families', () {
    expect(AppTypography.screenTitle.fontFamily, 'Poppins');
    expect(AppTypography.body.fontFamily, 'IBM Plex Sans');
    expect(AppTypography.timerLarge.fontFamily, 'IBM Plex Mono');
    expect(AppTypography.body.fontSize, greaterThanOrEqualTo(13));
    expect(AppTypography.timerLarge.fontSize, 52);
  });

  test('white on primary green meets WCAG AA contrast', () {
    expect(
      _contrastRatio(AppColors.onPrimary, AppColors.primary),
      greaterThanOrEqualTo(4.5),
    );
  });
}

double _contrastRatio(Color foreground, Color background) {
  final lighter = foreground.computeLuminance() > background.computeLuminance()
      ? foreground
      : background;
  final darker = foreground == lighter ? background : foreground;
  return (lighter.computeLuminance() + 0.05) /
      (darker.computeLuminance() + 0.05);
}
