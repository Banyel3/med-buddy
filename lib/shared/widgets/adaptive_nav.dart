import 'package:flutter/material.dart';

/// Adaptive nav item definition shared between rail and bar.
class AdaptiveNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String routeName;

  const AdaptiveNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.routeName,
  });
}
