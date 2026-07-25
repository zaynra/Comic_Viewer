import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// OmnivousReader Design System — Progress Chip
///
/// A small label showing reading progress (e.g., "90%", "15/32", "NEW").
/// Uses Geist-style typography for a technical, precise feel.
class ProgressChip extends StatelessWidget {
  const ProgressChip({
    super.key,
    required this.label,
    this.color,
    this.backgroundColor,
    this.showBookmark = false,
  });

  final String label;
  final Color? color;
  final Color? backgroundColor;
  final bool showBookmark;

  /// Factory for percentage display (e.g., "90%")
  factory ProgressChip.percentage({
    Key? key,
    required double progress,
  }) {
    return ProgressChip(
      key: key,
      label: '${(progress * 100).round()}%',
      color: progress >= 1.0 ? AppColors.primary : AppColors.onSurface,
    );
  }

  /// Factory for page counter (e.g., "15/32")
  factory ProgressChip.pageCounter({
    Key? key,
    required int current,
    required int total,
  }) {
    return ProgressChip(
      key: key,
      label: '$current / $total',
      color: AppColors.primary,
    );
  }

  /// Factory for "New" badge
  factory ProgressChip.newBadge({Key? key}) {
    return ProgressChip(
      key: key,
      label: 'NEW',
      color: AppColors.primary,
    );
  }

  /// Factory for chapter label (e.g., "#16")
  factory ProgressChip.chapter({
    Key? key,
    required int number,
  }) {
    return ProgressChip(
      key: key,
      label: '#$number',
      color: AppColors.onSurfaceVariant,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surfaceContainer.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.05,
              color: color ?? AppColors.onSurface,
            ),
          ),
          if (showBookmark) ...[
            const SizedBox(width: 4),
            const Icon(
              Icons.bookmark,
              size: 12,
              color: AppColors.tertiary,
            ),
          ],
        ],
      ),
    );
  }
}
