import 'package:flutter/material.dart';

/// Omnivious Reader Design System — Border Radius Tokens
/// Source: design/lumina_reader/DESIGN.md
class AppRadius {
  AppRadius._();

  // ──────────────────────────────────────────────
  // Radius Tokens
  // ──────────────────────────────────────────────
  static const double none = 0;
  static const double xs = 2;     // 0.125rem
  static const double sm = 4;     // 0.25rem
  static const double md = 8;     // 0.5rem (DEFAULT)
  static const double lg = 12;    // 0.75rem (xl in tailwind config)
  static const double xl = 16;    // 1rem
  static const double xxl = 24;   // 1.5rem (xl in DESIGN.md)
  static const double xxxl = 32;  // 2rem (bottom sheet top corners)
  static const double full = 9999;

  // ──────────────────────────────────────────────
  // BorderRadius Presets
  // ──────────────────────────────────────────────
  static BorderRadius get radiusNone => BorderRadius.zero;
  static BorderRadius get radiusXs => BorderRadius.circular(xs);
  static BorderRadius get radiusSm => BorderRadius.circular(sm);
  static BorderRadius get radiusMd => BorderRadius.circular(md);
  static BorderRadius get radiusLg => BorderRadius.circular(lg);
  static BorderRadius get radiusXl => BorderRadius.circular(xl);
  static BorderRadius get radiusXxl => BorderRadius.circular(xxl);
  static BorderRadius get radiusXxxl => BorderRadius.circular(xxxl);
  static BorderRadius get pill => BorderRadius.circular(full);

  // ──────────────────────────────────────────────
  // Semantic Aliases
  // ──────────────────────────────────────────────

  /// Comic/series cover cards
  static BorderRadius get comic => BorderRadius.circular(lg);

  /// Full-radius (pill shape)
  static BorderRadius get fullRadius => BorderRadius.circular(full);

  /// Bottom sheet top corners only
  static BorderRadius get bottomSheet => const BorderRadius.vertical(
        top: Radius.circular(xxxl),
      );

  /// Glass bottom navigation pill
  static BorderRadius get bottomNav => BorderRadius.circular(full);

  /// Thumbnail grid items
  static BorderRadius get thumbnail => BorderRadius.circular(md);
}
