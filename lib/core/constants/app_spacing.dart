/// OmnivousReader Design System — Spacing Tokens
/// Source: design/lumina_reader/DESIGN.md
/// Base grid: 4px
class AppSpacing {
  AppSpacing._();

  // ──────────────────────────────────────────────
  // Base Grid (4px increments)
  // ──────────────────────────────────────────────
  static const double base = 4;
  static const double xs = 4;   // 1 × base
  static const double sm = 8;   // 2 × base
  static const double md = 16;  // 4 × base
  static const double lg = 24;  // 6 × base
  static const double xl = 32;  // 8 × base

  // ──────────────────────────────────────────────
  // Layout
  // ──────────────────────────────────────────────
  static const double gutter = 12;
  static const double safeMargin = 20;

  // ──────────────────────────────────────────────
  // Component-specific
  // ──────────────────────────────────────────────
  static const double buttonHeight = 48;
  static const double iconButtonSize = 48;
  static const double thumbWidth = 64;
  static const double thumbHeight = 96;
  static const double coverWidthMobile = 192;
  static const double coverWidthDesktop = 256;

  // ──────────────────────────────────────────────
  // Deprecated — kept for backward compat
  // ──────────────────────────────────────────────
  @Deprecated('Use AppSpacing.gutter instead')
  static const double gutterMobile = 12;
  @Deprecated('Use AppSpacing.md instead')
  static const double marginMobile = 16;
}
