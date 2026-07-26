import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';

/// Omnivious Reader Design System — Page Scrub Slider
///
/// A floating pill-shaped page navigation slider with backdrop blur.
/// Shows current page label, progress bar with glow handle, and total pages.
class PageSlider extends StatelessWidget {
  const PageSlider({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onChanged,
    this.minWidth = 300,
    this.maxWidth = 448,
  });

  final int currentPage;
  final int totalPages;
  final ValueChanged<double>? onChanged;
  final double minWidth;
  final double maxWidth;

  double get progress =>
      totalPages > 0 ? (currentPage - 1) / (totalPages - 1).clamp(0, 1) : 0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: minWidth,
          maxWidth: maxWidth,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHighest.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(
                  color: AppColors.glassBorderSubtle,
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Current page label
                  SizedBox(
                    width: 32,
                    child: Text(
                      '$currentPage',
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Slider
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: AppColors.surfaceContainer,
                        thumbColor: AppColors.primary,
                        overlayColor: AppColors.primary.withValues(alpha: 0.1),
                        trackHeight: 8,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8,
                          elevation: 4,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 16,
                        ),
                      ),
                      child: Slider(
                        value: progress.clamp(0.0, 1.0),
                        onChanged: onChanged != null
                            ? (value) {
                                final page =
                                    (value * (totalPages - 1)).round() + 1;
                                onChanged!(page.toDouble());
                              }
                            : null,
                      ),
                    ),
                  ),

                  // Total pages label
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 32,
                    child: Text(
                      '$totalPages',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
