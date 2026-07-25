import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';

/// OmnivousReader Design System — Glassmorphism Bottom Sheet
///
/// A modal bottom sheet with rounded top corners, drag handle,
/// and max height constraint. Used for settings, chapter lists, etc.
class GlassBottomSheet extends StatelessWidget {
  const GlassBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.onClose,
    this.maxHeightRatio = 0.85,
    this.showDragHandle = true,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final VoidCallback? onClose;
  final double maxHeightRatio;
  final bool showDragHandle;

  /// Show the glass bottom sheet as a modal.
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    String? subtitle,
    VoidCallback? onClose,
    double maxHeightRatio = 0.85,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      builder: (_) => GlassBottomSheet(
        title: title,
        subtitle: subtitle,
        onClose: onClose,
        maxHeightRatio: maxHeightRatio,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * maxHeightRatio;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: AppRadius.bottomSheet,
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000), // black/40
                blurRadius: 40,
                offset: Offset(0, -10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              if (showDragHandle)
                const Padding(
                  padding: EdgeInsets.only(
                    top: AppSpacing.sm,
                    bottom: AppSpacing.md,
                  ),
                  child: Center(
                    child: _DragHandle(),
                  ),
                ),

              // Header
              if (title != null || onClose != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (title != null)
                              Text(
                                title!,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitle!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.1,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (onClose != null)
                        IconButton(
                          onPressed: onClose,
                          icon: const Icon(
                            Icons.close,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.safeMargin,
                  ),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 6,
      decoration: BoxDecoration(
        color: AppColors.outlineVariant,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
