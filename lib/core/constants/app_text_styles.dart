import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Omnivious Reader Design System — Typography Tokens
/// Source: design/lumina_reader/DESIGN.md
///
/// Fonts:
/// - Inter: All UI text (headlines, titles, body, labels)
class AppTextStyles {
  AppTextStyles._();

  // ──────────────────────────────────────────────
  // Headlines (Inter)
  // ──────────────────────────────────────────────

  /// 28px / 34px / 700 / letter-spacing: -0.02em
  static TextStyle get headlineLg => GoogleFonts.inter(
        fontSize: 28,
        height: 34 / 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02,
        color: AppColors.onSurface,
      );

  /// 24px / 30px / 700 — mobile variant
  static TextStyle get headlineLgMobile => GoogleFonts.inter(
        fontSize: 24,
        height: 30 / 24,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
      );

  /// 22px / 28px / 600
  static TextStyle get headlineMd => GoogleFonts.inter(
        fontSize: 22,
        height: 28 / 22,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      );

  // ──────────────────────────────────────────────
  // Titles (Inter)
  // ──────────────────────────────────────────────

  /// 18px / 24px / 600
  static TextStyle get titleLg => GoogleFonts.inter(
        fontSize: 18,
        height: 24 / 18,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      );

  // ──────────────────────────────────────────────
  // Body (Inter)
  // ──────────────────────────────────────────────

  /// 16px / 24px / 400
  static TextStyle get bodyLg => GoogleFonts.inter(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurface,
      );

  /// 14px / 20px / 400
  static TextStyle get bodyMd => GoogleFonts.inter(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurface,
      );

  // ──────────────────────────────────────────────
  // Labels
  // ──────────────────────────────────────────────

  /// 12px / 16px / 500 / letter-spacing: 0.05em
  static TextStyle get labelMd => GoogleFonts.inter(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.05,
        color: AppColors.onSurfaceVariant,
      );

  // ──────────────────────────────────────────────
  // Convenience: Colored Variants
  // ──────────────────────────────────────────────

  static TextStyle get headlineLgPrimary =>
      headlineLg.copyWith(color: AppColors.primary);

  static TextStyle get headlineMdPrimary =>
      headlineMd.copyWith(color: AppColors.primary);

  static TextStyle get titleLgPrimary =>
      titleLg.copyWith(color: AppColors.primary);

  static TextStyle get bodyLgVariant =>
      bodyLg.copyWith(color: AppColors.onSurfaceVariant);

  static TextStyle get bodyMdVariant =>
      bodyMd.copyWith(color: AppColors.onSurfaceVariant);

  static TextStyle get labelMdPrimary =>
      labelMd.copyWith(color: AppColors.primary);

  static TextStyle get labelMdTertiary =>
      labelMd.copyWith(color: AppColors.tertiary);
}
