import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';

/// OmnivousReader Design System — Glassmorphism Bottom Navigation
///
/// A floating pill-shaped bottom navigation bar with backdrop blur.
/// Positioned 20px from bottom (safeMargin) with horizontal margins.
class GlassBottomNav extends StatelessWidget {
  const GlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<GlassBottomNavItem> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.safeMargin,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.pill,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh.withValues(alpha: 0.9),
              borderRadius: AppRadius.pill,
              border: Border.all(
                color: AppColors.glassBorder,
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGlow.withValues(alpha: 0.15),
                  blurRadius: 24,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (index) {
                final item = items[index];
                final isActive = index == currentIndex;
                return _NavButton(
                  item: item,
                  isActive: isActive,
                  onTap: () => onTap(index),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassBottomNavItem {
  const GlassBottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final GlassBottomNavItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryContainer.withValues(alpha: 0.3)
              : Colors.transparent,
          borderRadius: AppRadius.pill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? item.activeIcon : item.icon,
              size: 24,
              color: isActive
                  ? AppColors.primary
                  : AppColors.onSurfaceVariant,
            ),
            if (isActive) ...[
              const SizedBox(width: AppSpacing.xs),
              Text(
                item.label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                  letterSpacing: 0.05,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
