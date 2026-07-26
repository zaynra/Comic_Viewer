import 'package:flutter/material.dart';

/// Omnivious Reader Design System — Material 3 Dark Color Tokens
/// Source: design/lumina_reader/DESIGN.md
/// Do not hardcode colors in widgets — always reference these.
class AppColors {
  AppColors._();

  // ──────────────────────────────────────────────
  // Primary
  // ──────────────────────────────────────────────
  static const primary = Color(0xFFC0C1FF);
  static const onPrimary = Color(0xFF1000A9);
  static const primaryContainer = Color(0xFF8083FF);
  static const onPrimaryContainer = Color(0xFF0D0096);
  static const inversePrimary = Color(0xFF494BD6);

  // ──────────────────────────────────────────────
  // Secondary
  // ──────────────────────────────────────────────
  static const secondary = Color(0xFFB9C8DE);
  static const onSecondary = Color(0xFF233143);
  static const secondaryContainer = Color(0xFF39485A);
  static const onSecondaryContainer = Color(0xFFA7B6CC);

  // ──────────────────────────────────────────────
  // Tertiary
  // ──────────────────────────────────────────────
  static const tertiary = Color(0xFFFFB783);
  static const onTertiary = Color(0xFF4F2500);
  static const tertiaryContainer = Color(0xFFD97721);
  static const onTertiaryContainer = Color(0xFF452000);

  // ──────────────────────────────────────────────
  // Error
  // ──────────────────────────────────────────────
  static const error = Color(0xFFFFB4AB);
  static const onError = Color(0xFF690005);
  static const errorContainer = Color(0xFF93000A);
  static const onErrorContainer = Color(0xFFFFDAD6);

  // ──────────────────────────────────────────────
  // Surface
  // ──────────────────────────────────────────────
  static const surface = Color(0xFF0B1326);
  static const onSurface = Color(0xFFDAE2FD);
  static const onSurfaceVariant = Color(0xFFC7C4D7);
  static const surfaceDim = Color(0xFF0B1326);
  static const surfaceBright = Color(0xFF31394D);
  static const surfaceTint = Color(0xFFC0C1FF);

  // ──────────────────────────────────────────────
  // Surface Containers (darkest → lightest)
  // ──────────────────────────────────────────────
  static const surfaceContainerLowest = Color(0xFF060E20);
  static const surfaceContainerLow = Color(0xFF131B2E);
  static const surfaceContainer = Color(0xFF171F33);
  static const surfaceContainerHigh = Color(0xFF222A3D);
  static const surfaceContainerHighest = Color(0xFF2D3449);

  // ──────────────────────────────────────────────
  // Inverse
  // ──────────────────────────────────────────────
  static const inverseSurface = Color(0xFFDAE2FD);
  static const inverseOnSurface = Color(0xFF283044);

  // ──────────────────────────────────────────────
  // Outline
  // ──────────────────────────────────────────────
  static const outline = Color(0xFF908FA0);
  static const outlineVariant = Color(0xFF464554);

  // ──────────────────────────────────────────────
  // Background
  // ──────────────────────────────────────────────
  static const background = Color(0xFF0B1326);
  static const onBackground = Color(0xFFDAE2FD);

  // ──────────────────────────────────────────────
  // Surface Variant
  // ──────────────────────────────────────────────
  static const surfaceVariant = Color(0xFF2D3449);

  // ──────────────────────────────────────────────
  // Fixed (Light theme support)
  // ──────────────────────────────────────────────
  static const primaryFixed = Color(0xFFE1E0FF);
  static const primaryFixedDim = Color(0xFFC0C1FF);
  static const onPrimaryFixed = Color(0xFF07006C);
  static const onPrimaryFixedVariant = Color(0xFF2F2EBE);

  static const secondaryFixed = Color(0xFFD4E4FA);
  static const secondaryFixedDim = Color(0xFFB9C8DE);
  static const onSecondaryFixed = Color(0xFF0D1C2D);
  static const onSecondaryFixedVariant = Color(0xFF39485A);

  static const tertiaryFixed = Color(0xFFFFDCC5);
  static const tertiaryFixedDim = Color(0xFFFFB783);
  static const onTertiaryFixed = Color(0xFF301400);
  static const onTertiaryFixedVariant = Color(0xFF703700);

  // ──────────────────────────────────────────────
  // Semantic / Custom (not from Material tokens)
  // ──────────────────────────────────────────────

  /// Glassmorphism border (dark mode)
  static const glassBorder = Color(0x1AFFFFFF); // white/10

  /// Glassmorphism border subtle
  static const glassBorderSubtle = Color(0x0DFFFFFF); // white/5

  /// Primary glow shadow color
  static const primaryGlow = Color(0x99C0C1FF); // primary with 60% opacity

  /// Scrim overlay
  static const scrim = Color(0x99000000); // black/60

  /// Progress track background
  static const progressTrack = Color(0xFF171F33); // surface-container

  /// Progress fill
  static const progressFill = Color(0xFFC0C1FF); // primary

  /// Legacy aliases (deprecated — use tokens above)
  @Deprecated('Use outlineVariant instead')
  static const chapterCardBorder = outlineVariant;
}
