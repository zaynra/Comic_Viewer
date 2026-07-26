import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Omnivious Reader Design System — Status Badge
///
/// Positioned badge for comic cards (e.g., "NEW", "90%").
/// Typically placed in the top-right or top-left corner of a thumbnail.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.position = StatusBadgePosition.topRight,
    this.color,
    this.backgroundColor,
  });

  final String label;
  final StatusBadgePosition position;
  final Color? color;
  final Color? backgroundColor;

  /// Factory for "NEW" badge
  factory StatusBadge.new_({Key? key, StatusBadgePosition position = StatusBadgePosition.topRight}) {
    return StatusBadge(
      key: key,
      label: 'NEW',
      position: position,
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceContainerHigh,
    );
  }

  /// Factory for percentage badge
  factory StatusBadge.percentage({
    Key? key,
    required double progress,
    StatusBadgePosition position = StatusBadgePosition.topLeft,
  }) {
    return StatusBadge(
      key: key,
      label: '${(progress * 100).round()}%',
      position: position,
      color: AppColors.onSurface,
      backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.8),
    );
  }

  /// Factory for "New Chapter" badge
  factory StatusBadge.newChapter({Key? key, StatusBadgePosition position = StatusBadgePosition.topLeft}) {
    return StatusBadge(
      key: key,
      label: 'NEW CHAPTER',
      position: position,
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceContainerHigh.withValues(alpha: 0.9),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: position == StatusBadgePosition.topLeft ||
              position == StatusBadgePosition.topRight
          ? 8
          : null,
      bottom: position == StatusBadgePosition.bottomLeft ||
              position == StatusBadgePosition.bottomRight
          ? 8
          : null,
      left: position == StatusBadgePosition.topLeft ||
              position == StatusBadgePosition.bottomLeft
          ? 8
          : null,
      right: position == StatusBadgePosition.topRight ||
              position == StatusBadgePosition.bottomRight
          ? 8
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: AppColors.glassBorderSubtle,
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.08,
            color: color ?? AppColors.onSurface,
          ),
        ),
      ),
    );
  }
}

enum StatusBadgePosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}
