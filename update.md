# OmnivousReader — Update Log

## Last Updated: 2026-07-25 16:45 WIB

---

## 2026-07-25: Design System Implementation + PDF Fixes

### Branch: `desain`

#### Design Tokens & Theme
- Created full Material 3 dark theme with OmnivousReader colors
- Primary: `#C0C1FF` (lavender blue), Tertiary: `#FFB783` (orange)
- Background: `#0B1326` (deep navy), Surface hierarchy: `#060E20` → `#2D3449`
- Glassmorphism tokens: glassBorder, glassBorderSubtle, primaryGlow
- 4px grid spacing system, radius tokens (sm→full + semantic presets)
- System Roboto font (removed Google Fonts for offline compatibility)

#### Glassmorphism Components (8 widgets)
- GlassAppBar, GlassBottomNav, GlassBottomSheet, GlassCard
- PrimaryButton, ProgressChip, StatusBadge, PageSlider
- All use BackdropFilter blur + semi-transparent surfaces

#### UI Phases (12/12 complete)
- Splash: AnimatedBuilder glow pulse, logo image
- Onboarding: Fade + slide-in animations
- Home: Glass top bar, filter tabs (UI only), 2-column comic grid
- Series Detail: Hero header, synopsis, genres, chapter list
- Reader: Glass top/bottom bars, page slider, settings sheet
- Settings: Bottom sheet style with all controls
- History: Glassmorphism cards, time-grouped
- Thumbnail Viewer: 3-column grid, jump-to-page
- Routes: 8 routes with custom transitions
- All pages use consistent design tokens

#### App Icon & Branding
- flutter_launcher_icons with custom OR logo
- assets/images/or_logo.png used in splash, onboarding, home

#### PDF Reader Fixes
- Removed Google Fonts dependency (caused gray screen offline)
- Changed GlassBottomNav from Positioned to Padding (fixed cast error)
- Default readingMode: vertical (webtoon scroll style)
- Default fitMode: fitWidth (fills screen width)
- SharedPreferences defaults fixed (index 2=vertical, 1=fitWidth)
- Render resolution increased 1.5x → 2.0x

#### Known Issues (to fix next)
- Filter tabs: UI only, no filtering logic
- History: Not tracking reading activity
- Chapter page count: Shows "0 Pages"
- Download button: Unnecessary for local files
- Reader controls: Hidden by default
- PDF loading: Spinner only, no progressive loading

---

## 2026-07-24: MVP Implementation (Phases 0-10)

### All functional features implemented:
- Phase 0: Skeleton, Riverpod, GoRouter, SAF picker
- Phase 1: SQLite schema, scanner, natural sort
- Phase 2: Library grid + Series Detail
- Phase 3: PDF reader with pdfx, LRU cache
- Phase 4: Reading progress persistence
- Phase 5: Chapter navigation (prev/next/auto-next)
- Phase 6: Cover detection + auto-generate
- Phase 7: Search, Favorites, Recent
- Phase 8: File system watcher
- Phase 9: Settings + error handling
- Phase 10: Metadata JSON import

### Post-MVP:
- Manual path input (SAF bypass)
- Emulator storage permission workaround (`appops set`)
