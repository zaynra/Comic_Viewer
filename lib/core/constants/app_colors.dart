import 'package:flutter/material.dart';

/// Design tokens extracted from the Series Detail mockup (Material 3 dark scheme).
/// Do not hardcode colors in widgets — always reference these.
class AppColors {
  AppColors._();

  static const primary = Color(0xFFCFBCFF);
  static const onPrimary = Color(0xFF381E72);
  static const primaryContainer = Color(0xFF6750A4);
  static const onPrimaryContainer = Color(0xFFE0D2FF);

  static const background = Color(0xFF131313);
  static const onBackground = Color(0xFFE2E2E2);

  static const surface = Color(0xFF131313);
  static const onSurface = Color(0xFFE2E2E2);
  static const onSurfaceVariant = Color(0xFFCBC4D2);

  static const surfaceBright = Color(0xFF393939);

  static const surfaceContainerLowest = Color(0xFF0E0E0E);
  static const surfaceContainerLow = Color(0xFF1B1B1B);
  static const surfaceContainer = Color(0xFF1F1F1F);
  static const surfaceContainerHigh = Color(0xFF2A2A2A);
  static const surfaceContainerHighest = Color(0xFF353535);

  static const outline = Color(0xFF948E9C);
  static const outlineVariant = Color(0xFF494551);

  static const secondary = Color(0xFFC8C6C5);
  static const secondaryContainer = Color(0xFF474746);

  static const error = Color(0xFFFFB4AB);
  static const errorContainer = Color(0xFF93000A);
  static const onError = Color(0xFF690005);
  static const onErrorContainer = Color(0xFFFFDAD6);

  /// Chapter card border (matches `#2C2C2C` from the mockup).
  static const chapterCardBorder = Color(0xFF2C2C2C);
  static const progressTrack = Color(0xFF212121);
  static const progressFill = Color(0xFF6750A4);
}
