# Comic Viewer - Development Progress

## Current Phase: Design System + Bug Fixes (Branch: desain)

## Last Updated: 2026-07-25 16:45 WIB

---

## Architecture
- **Framework:** Flutter 3.29.2
- **State:** Riverpod
- **Routing:** GoRouter
- **DB:** sqflite (SQLite)
- **PDF:** pdfx (v2.6.0)
- **Design System:** Custom Material 3 dark theme + Glassmorphism
- **Font:** System Roboto (removed Google Fonts dependency)
- **GitHub:** `https://github.com/zaynra/Comic_Viewer.git`
- **Branches:** `main` (base), `desain` (design + fixes)

---

## Implementation Timeline

### Phase 0 — Skeleton ✅ (2026-07-24)
- Flutter project with Clean Architecture
- Riverpod, GoRouter, dark theme with lavender accent
- SAF folder picker, SharedPreferences persistence
- Fixed NDK version mismatch

### Phase 1 — Data Layer & Library Scanner ✅ (2026-07-24)
- SQLite schema: series, chapters, library_index
- Domain entities, repositories, recursive scanner
- Natural sort for chapter names

### Phase 2 — Library UI + Series Detail ✅ (2026-07-24)
- 2-column grid, series name, chapter count
- Series Detail: hero cover + gradient overlay, chip badges
- Chapter cards with progress bar / check_circle

### Phase 2b — Reader UI Shell & Settings UI Shell ✅ (2026-07-24)
- Reader page shell with overlay UI
- Settings page with sections

### Phase 3 — Reader Core ✅ (2026-07-24)
- pdfx integration, page-by-page async render
- LRU cache (5 pages), pinch zoom
- Tap left/right for page navigation

### Phase 4 — Reading Progress ✅ (2026-07-24)
- reading_progress table, save/restore on page change
- "Lanjutkan Membaca" section on HomePage

### Phase 5 — Chapter Navigation ✅ (2026-07-24)
- Prev/Next chapter buttons
- Auto-next dialog at last page

### Phase 6 — Cover & Thumbnail ✅ (2026-07-24)
- Custom cover detection + auto-generate from PDF first page
- Thumbnails table

### Phase 7 — Search, Favorites, Recent ✅ (2026-07-24)
- Favorites and recent tables
- Realtime search, favorites toggle

### Phase 8 — Incremental File Monitoring ✅ (2026-07-24)
- watcher package, debounced change detection

### Phase 9 — Settings & Polish ✅ (2026-07-24)
- Theme mode, reading direction, keep screen on, error handling

### Phase 10 — Metadata JSON Import ✅ (2026-07-24)
- MetadataParser for JSON metadata
- Series/chapter metadata parsing

---

## Design System Implementation (Branch: desain) — 2026-07-25

### Design Tokens ✅
- app_colors.dart: 30+ Material 3 color tokens
- app_spacing.dart: 4px grid system
- app_radius.dart: Radius tokens + semantic presets
- app_text_styles.dart: System Roboto (was Inter/Geist)
- app_theme.dart: Full Material 3 ThemeData

### Glassmorphism Components ✅
- GlassAppBar, GlassBottomNav, GlassBottomSheet, GlassCard
- PrimaryButton, ProgressChip, StatusBadge, PageSlider

### All 12 UI Phases ✅
- Splash, Onboarding, Home, Series Detail, Reader, Settings
- History, Thumbnail Viewer, Routes, Animations

### App Icon & Branding ✅
- flutter_launcher_icons with custom OR logo
- assets/images/or_logo.png

### Design Refinements ✅
- Glassmorphism on home top bar, history cards
- Settings bottom sheet style
- Synopsis + genres in series detail

---

## PDF Reader Fixes (Branch: desain) — 2026-07-25

### Gray Screen Fix ✅
- Removed Google Fonts (Inter/Geist) → system Roboto
- Fixed `GoogleFonts.getFont('Geist')` offline exception

### FlexParentData Cast Fix ✅
- GlassBottomNav: Positioned → Padding (works in both Stack & Column)

### PDF Fit-to-Width Fix ✅
- Default readingMode → vertical (webtoon scroll)
- Default fitMode → fitWidth (fills screen width)
- SharedPreferences defaults fixed
- Render resolution 1.5x → 2.0x

---

## Known Issues (See ISSUES.md for details)

| Issue | Severity | Status |
|-------|----------|--------|
| Filter tabs not functional | High | OPEN |
| Recent activity not working | High | OPEN |
| Chapter shows "0 Pages" | Medium | OPEN |
| Download button unnecessary | Low | OPEN |
| Reader menu bar hidden by default | Critical | OPEN |
| PDF loading UX (spinner only) | High | OPEN |
| PDF loading too slow | Medium | OPEN |

---

## Build Info
- **APK:** `build\app\outputs\flutter-apk\app-release.apk` (23.1MB)
- **Test device:** Android emulator (emulator-5554)
- **Test PDF:** Revenge of the Iron-Blooded Sword Hound (Chapter 0001, 5 pages, ~23MB)
- **Git commit (desain):** cbaaf02

---

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| flutter_riverpod | ^2.5.1 | State management |
| go_router | ^14.2.0 | Routing |
| file_picker | ^8.1.2 | SAF folder picker |
| sqflite | ^2.3.0 | SQLite database |
| pdfx | ^2.6.0 | PDF rendering |
| path_provider | ^2.1.2 | File paths |
| shared_preferences | ^2.3.2 | Settings persistence |
| watcher | ^1.1.0 | File system monitoring |
| material_symbols_icons | ^4.2719.3 | Material Symbols icons |
| path | ^1.8.0 | Path manipulation |
| flutter_launcher_icons | ^0.14.3 | App icon generation |
| wakelock_plus | ^1.2.8 | Keep screen on during reading |

---

## SQLite Schema (v5)

```sql
series: id, name, path (UNIQUE), cover_path, author, description, genres, created_at
chapters: id, series_id (FK), name, file_path (UNIQUE), sort_order, total_pages, current_page, is_read
library_index: id, folder_path (UNIQUE), last_scanned_at
reading_progress: id, chapter_id (FK, UNIQUE), current_page, zoom_level, last_opened_at
thumbnails: id, series_id (FK, UNIQUE), source, file_path, created_at
favorites: id, series_id (FK, UNIQUE), created_at
recent: id, series_id (FK), last_opened_at (indexed)
```

---

## Next Steps (Priority Order)

1. **Fix chapter page count** — populate `total_pages` during scan
2. **Remove download button** from chapter list
3. **Fix reader controls** — show by default on entry
4. **Progressive PDF loading** — blurred preview → sharpen
5. **Fix filter tabs** — implement filtering logic
6. **Fix recent activity** — save reading history on chapter open
7. **Push all fixes to desain branch**
