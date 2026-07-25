# OmnivousReader Design Implementation Progress

## Target Design: `design/` folder (Lumina Reader Design System)

---

## Phase 1: Design Token Overhaul
**Status: COMPLETED** (2026-07-25)

| File | Status | Notes |
|------|--------|-------|
| `app_colors.dart` | DONE | Full Material Design 3 token map (30+ colors, glassmorphism tokens, legacy aliases) |
| `app_spacing.dart` | DONE | 4px grid, gutter, safeMargin, component-specific spacing, deprecated old names |
| `app_radius.dart` | DONE | sm/md/lg/xl/2xl/3xl/full + semantic presets (comic, pill, bottomSheet, thumbnail) |
| `app_text_styles.dart` | DONE | System Roboto font (removed Google Fonts dependency) |
| `app_theme.dart` | DONE | Full ColorScheme, AppBar, Card, Button, BottomSheet, Slider, NavigationBar, Switch, Chip themes |

---

## Phase 2: Reusable Glassmorphism Components
**Status: COMPLETED** (2026-07-25)

| Widget | File | Status |
|--------|------|--------|
| `GlassAppBar` | `shared/widgets/glass_app_bar.dart` | DONE |
| `GlassBottomNav` | `shared/widgets/glass_bottom_nav.dart` | DONE (Padding-based, works in both Stack & Column) |
| `GlassBottomSheet` | `shared/widgets/glass_bottom_sheet.dart` | DONE |
| `GlassCard` | `shared/widgets/glass_card.dart` | DONE |
| `PrimaryButton` | `shared/widgets/primary_button.dart` | DONE |
| `ProgressChip` | `shared/widgets/progress_chip.dart` | DONE |
| `StatusBadge` | `shared/widgets/status_badge.dart` | DONE |
| `PageSlider` | `shared/widgets/page_slider.dart` | DONE |
| `widgets.dart` | `shared/widgets/widgets.dart` | DONE (barrel export) |

---

## Phase 3: Splash Screen
**Status: COMPLETED** (2026-07-25)

| Item | File | Status |
|------|------|--------|
| Splash page | `lib/presentation/splash/pages/splash_page.dart` | DONE |
| Logo asset | `assets/images/or_logo.png` | DONE |
| Route update | `app_router.dart` — `/splash` as initial route | DONE (currently skipped → home directly) |
| Glow animation | AnimatedBuilder with repeat pulse | DONE |

---

## Phase 4: Onboarding Screen
**Status: COMPLETED** (2026-07-25)

| Item | File | Status |
|------|------|--------|
| Onboarding page | `lib/presentation/onboarding/pages/onboarding_page.dart` | DONE |
| SharedPreferences flag | `onboarding_seen` set on "Get Started" tap | DONE |
| Route update | `app_router.dart` — `/onboarding` | DONE |
| Animation | Fade + slide-in for text content | DONE |

---

## Phase 5: Home Page Redesign
**Status: COMPLETED** (2026-07-25)

| Item | File | Status |
|------|------|--------|
| HomePage rewrite | `lib/presentation/home/pages/home_page.dart` | DONE |
| Glass top bar | OR logo + OmnivousReader title + action icons | DONE |
| Filter tabs | All Items / Folders / Recent / Favorites — **UI only, NOT functional** | PARTIAL |
| Comic grid cards | 2-column grid with aspect ratio 0.65, progress bar at bottom | DONE |
| Bottom nav | GlassBottomNav with Library / History / Settings | DONE |
| Empty state | Glassmorphism styled with PrimaryButton | DONE |

---

## Phase 6: Series Detail Redesign
**Status: COMPLETED** (2026-07-25)

| Item | File | Status |
|------|------|--------|
| SeriesDetail rewrite | `lib/presentation/series_detail/pages/series_detail_page.dart` | DONE |
| Hero section | Blurred cover bg (sigma 40), gradient overlay | DONE |
| Cover thumbnail | 192x288, rounded-xl, shadow-2xl | DONE |
| Metadata section | Title, author, description rows | DONE |
| Action buttons | Resume Reading (PrimaryButton) + bookmark + more | DONE |
| Chapter list | Glass cards with thumbnail placeholder, progress bar | DONE |
| **BUG: Page count** | Shows "0 Pages" for all chapters | BROKEN |
| **BUG: Download button** | Unnecessary for local files | TO REMOVE |

---

## Phase 7: Reader View Redesign
**Status: COMPLETED** (2026-07-25)

| Item | File | Status |
|------|------|--------|
| Reader rewrite | `lib/presentation/reader/pages/reader_page.dart` | DONE |
| Glass top bar | surfaceContainerHighest/80, backdrop-blur-xl | DONE |
| **BUG: Menu bar hidden** | Tap anywhere hides menu — no visible prev/next when controls hidden | BROKEN |
| Page badge | "15 / 248" counter | DONE |
| **BUG: Loading state** | Shows spinner on empty screen — no blurred preview | BROKEN |
| Settings sheet | Bottom sheet with brightness, view mode, scroll mode | DONE |
| Background | #060E20 (surfaceContainerLowest) | DONE |
| Tap toggle | Canvas tap → show/hide controls | DONE |
| Default fit mode | fitWidth (was fitScreen) | FIXED |
| Default reading mode | vertical (was single) | FIXED |
| Render resolution | 2.0x (was 1.5x) | FIXED |

---

## Phase 8: Settings Redesign
**Status: COMPLETED** (2026-07-25)

| Item | File | Status |
|------|------|--------|
| Settings rewrite | `lib/presentation/settings/pages/settings_page.dart` | DONE |
| Glass header | OR logo + OmnivousReader + SETTINGS label + close button | DONE |
| Brightness slider | Custom Slider with light_mode icons, primary thumb | DONE |
| View mode grid | 2x2 buttons: Fit Width/Height/Screen/Original | DONE |
| Scroll mode | Segmented: Vertical / Horizontal / Continuous | DONE |
| Display toggles | Dark Mode / Night Filter / Keep Screen On / Auto Continue | DONE |
| Reading section | Direction + Orientation with bottom sheet dialogs | DONE |
| About section | Version + Built with | DONE |

---

## Phase 9: History Screen (New)
**Status: PARTIAL** (2026-07-25)

| Item | File | Status |
|------|------|--------|
| History page | `lib/presentation/history/pages/history_page.dart` | DONE |
| History provider | `lib/presentation/history/providers/history_provider.dart` | DONE |
| Route | `/history` in `app_router.dart` | DONE |
| Time groups | "Today", "Yesterday", "Older" sections | DONE |
| Activity items | Thumbnail + title + chapter + progress bar | DONE |
| **BUG: Recent activity not working** | Does not track/read reading history | BROKEN |

---

## Phase 10: Thumbnail Viewer (New)
**Status: COMPLETED** (2026-07-25)

| Item | File | Status |
|------|------|--------|
| Thumbnail viewer | `lib/presentation/thumbnails/pages/thumbnail_viewer_page.dart` | DONE |
| Route | `/thumbnails` in `app_router.dart` with `ThumbnailViewerArgs` | DONE |
| 3-column grid | aspect-[1/1.4], rounded-lg | DONE |
| Active page | Primary border + glow shadow | DONE |
| Bottom jump bar | Page markers + "Jump to..." button | DONE |

---

## Phase 11: Navigation & Route Updates
**Status: COMPLETED** (2026-07-25)

| Route | Screen | Status |
|-------|--------|--------|
| `/splash` | SplashPage | DONE |
| `/onboarding` | OnboardingPage | DONE |
| `/` | HomePage | DONE |
| `/series` | SeriesDetailPage | DONE |
| `/reader` | ReaderPage | DONE |
| `/settings` | SettingsPage | DONE |
| `/history` | HistoryPage | DONE |
| `/thumbnails` | ThumbnailViewerPage | DONE |

---

## Phase 12: Polish & Animation
**Status: COMPLETED** (2026-07-25)

| Item | Status |
|------|--------|
| Page transitions (fade 300ms) | DONE |
| Page transitions (slide-up) | DONE |
| All animations use Curves.easeInOut / easeOutCubic | DONE |
| `flutter analyze` passes with 0 errors | DONE |

---

## Summary

| Phase | Description | Status |
|-------|-------------|--------|
| 1 | Design Token Overhaul | DONE |
| 2 | Reusable Glassmorphism Components | DONE |
| 3 | Splash Screen | DONE |
| 4 | Onboarding Screen | DONE |
| 5 | Home Page Redesign | DONE |
| 6 | Series Detail Redesign | DONE |
| 7 | Reader View Redesign | DONE |
| 8 | Settings Redesign | DONE |
| 9 | History Screen | PARTIAL (recent activity broken) |
| 10 | Thumbnail Viewer | DONE |
| 11 | Navigation & Routes | DONE |
| 12 | Polish & Animation | DONE |

**12 phases COMPLETE (design-wise). Functional bugs documented in ISSUES.md.**

---

## Design Refinements (Branch: desain)

### App Icon & Branding — DONE
### Splash Screen — DONE  
### Onboarding Screen — DONE
### Home Page Glassmorphism — DONE
### Settings Bottom Sheet — DONE
### Series Detail Synopsis & Genres — DONE
### History Glassmorphism Cards — DONE

### Font Fix (Branch: desain)
- Removed Google Fonts (Inter/Geist) dependency → system Roboto
- Fixed gray screen bug caused by `GoogleFonts.getFont('Geist')` exception offline
- Fixed `GlassBottomNav` Positioned-in-Column cast error

### PDF Fit-to-Width Fix (Branch: desain)
- Default readingMode → vertical (webtoon/AsuraScans style)
- Default fitMode → fitWidth (fills screen width)
- SharedPreferences defaults fixed (index 2=vertical, 1=fitWidth)
- Render resolution 1.5x → 2.0x

### Current APK: `build\app\outputs\flutter-apk\app-release.apk` (23.1MB)
### Git: `https://github.com/zaynra/Comic_Viewer.git` — branches: `main`, `desain`
