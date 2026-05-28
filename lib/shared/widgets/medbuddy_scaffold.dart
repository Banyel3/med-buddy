import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/device_utils.dart';

/// Adaptive shell — BottomNavigationBar on phone, NavigationRail on tablet.
class MedBuddyScaffold extends StatelessWidget {
  final Widget child;
  final String location;

  const MedBuddyScaffold({
    super.key,
    required this.child,
    required this.location,
  });

  static const _destinations = [
    _NavItem(
      route: AppRoute.home,
      path: '/home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    _NavItem(
      route: AppRoute.history,
      path: '/history',
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month_rounded,
      label: 'History',
    ),
    _NavItem(
      route: AppRoute.profile,
      path: '/profile',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  int get _selectedIndex {
    for (var i = 0; i < _destinations.length; i++) {
      if (location.startsWith(_destinations[i].path)) return i;
    }
    return 0;
  }

  void _go(BuildContext context, int index) {
    context.goNamed(_destinations[index].route);
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = DeviceUtils.isTablet(context);

    if (isTablet) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) => _go(context, i),
              labelType: NavigationRailLabelType.all,
              backgroundColor: AppColors.surface,
              indicatorColor: AppColors.primary.withValues(alpha: 0.12),
              selectedIconTheme: const IconThemeData(
                color: AppColors.primary,
                size: 28,
              ),
              unselectedIconTheme: const IconThemeData(
                color: AppColors.onSurface,
                size: 24,
              ),
              destinations: _destinations
                  .map(
                    (d) => NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.activeIcon),
                      label: Text(d.label),
                    ),
                  )
                  .toList(),
            ),
            const VerticalDivider(width: 1, color: AppColors.outline),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => _go(context, i),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        elevation: 0,
        height: 72,
        destinations: _destinations
            .map(
              (d) => NavigationDestination(
                icon: Icon(d.icon, color: AppColors.onSurface),
                selectedIcon: Icon(d.activeIcon, color: AppColors.primary),
                label: d.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _NavItem {
  final String route;
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.route,
    required this.path,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Page padding helper — wider on tablet.
EdgeInsets pagePadding(BuildContext context) {
  final isTablet = DeviceUtils.isTablet(context);
  return EdgeInsets.symmetric(
    horizontal: isTablet ? AppDimensions.space40 : AppDimensions.space20,
    vertical: AppDimensions.space24,
  );
}
