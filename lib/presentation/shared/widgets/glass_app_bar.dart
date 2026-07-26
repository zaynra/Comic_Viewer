import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';

/// Omnivious Reader Design System — Glassmorphism App Bar
///
/// A translucent top app bar with backdrop blur and subtle border.
/// Usage: Wrap in `SafeArea` or position with `Stack` + `Positioned`.
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    this.leading,
    this.title,
    this.actions,
    this.centerTitle = false,
    this.showBorder = true,
  });

  final Widget? leading;
  final Widget? title;
  final List<Widget>? actions;
  final bool centerTitle;
  final bool showBorder;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: preferredSize.height,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.7),
            border: showBorder
                ? const Border(
                    bottom: BorderSide(
                      color: AppColors.glassBorderSubtle,
                      width: 0.5,
                    ),
                  )
                : null,
          ),
          child: Row(
            children: [
              if (leading != null) leading!,
              if (centerTitle)
                Expanded(
                  child: Center(child: title),
                )
              else
                Expanded(child: title ?? const SizedBox()),
              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );
  }
}
