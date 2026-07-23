import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:cedsif_overtime_mobile/theme/app_colors.dart';
import 'package:cedsif_overtime_mobile/theme/app_spacing.dart';
import 'package:cedsif_overtime_mobile/theme/app_typography.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.body,
    this.showTopBar = false,
    this.showBottomNavigation = false,
    this.currentIndex = 0,
    this.onDestinationSelected,
    this.onMenuPressed,
    this.backgroundColor = AppColors.background,
    super.key,
  });

  final Widget body;
  final bool showTopBar;
  final bool showBottomNavigation;
  final int currentIndex;
  final ValueChanged<int>? onDestinationSelected;
  final VoidCallback? onMenuPressed;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: backgroundColor,
    body: SafeArea(
      bottom: !showBottomNavigation,
      child: Column(
        children: [
          if (showTopBar)
            _PortalTopBar(onMenuPressed: onMenuPressed)
          else
            const SizedBox.shrink(),
          Expanded(child: body),
        ],
      ),
    ),
    bottomNavigationBar: showBottomNavigation
        ? SafeArea(
            top: false,
            child: NavigationBar(
              selectedIndex: currentIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home_rounded),
                  label: 'navigation.home'.tr(),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.history_rounded),
                  label: 'navigation.history'.tr(),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.person_outline_rounded),
                  label: 'navigation.profile'.tr(),
                ),
              ],
            ),
          )
        : null,
  );
}

class _PortalTopBar extends StatelessWidget {
  const _PortalTopBar({this.onMenuPressed});

  final VoidCallback? onMenuPressed;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.canvas,
    child: SizedBox(
      height: AppSpacing.topBarHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox.square(
                dimension: AppSpacing.touchTarget,
                child: IconButton(
                  onPressed: onMenuPressed,
                  tooltip: 'navigation.menu'.tr(),
                  icon: const Icon(
                    Icons.menu_rounded,
                    color: AppColors.textPrimary,
                    size: AppSpacing.iconLarge,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space56,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/images/moz.svg',
                      width: AppSpacing.emblemSmall,
                      height: AppSpacing.emblemSmall,
                      semanticsLabel: 'app.emblem'.tr(),
                    ),
                    const SizedBox(width: AppSpacing.space12),
                    Text(
                      'app.title'.tr(),
                      style: AppTypography.screenTitle.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
