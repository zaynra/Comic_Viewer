import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const String _fontFamily = 'Roboto';

  static TextStyle get headlineLg => const TextStyle(
        fontSize: 28,
        height: 34 / 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02,
        color: AppColors.onSurface,
        fontFamily: _fontFamily,
      );

  static TextStyle get headlineLgMobile => const TextStyle(
        fontSize: 24,
        height: 30 / 24,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
        fontFamily: _fontFamily,
      );

  static TextStyle get headlineMd => const TextStyle(
        fontSize: 22,
        height: 28 / 22,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
        fontFamily: _fontFamily,
      );

  static TextStyle get titleLg => const TextStyle(
        fontSize: 18,
        height: 24 / 18,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
        fontFamily: _fontFamily,
      );

  static TextStyle get bodyLg => const TextStyle(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurface,
        fontFamily: _fontFamily,
      );

  static TextStyle get bodyMd => const TextStyle(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurface,
        fontFamily: _fontFamily,
      );

  static TextStyle get labelMd => const TextStyle(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.05,
        color: AppColors.onSurfaceVariant,
        fontFamily: _fontFamily,
      );

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
