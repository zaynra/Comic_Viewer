# TODO: PDF Loading Optimization & Settings Fixes

## Overview
Optimize PDF loading for **vertical scroll only** (webtoon 20-60MB) with **zero blank screens**, progressive rendering, and fix all broken settings buttons.

**Target Branch:** `desain` (development branch)
**Base:** Current `backup` branch state (commit ab5bea5)

---

## Phase 0: Settings & Configuration Foundation

### 0.1 Add Render Scale Setting (1.5x / 2.0x) ✅
- [x] Add `RenderScale` enum to `settings_provider.dart`:
  ```dart
  enum RenderScale { scale150, scale200 }  // 1.5x, 2.0x
  ```
- [x] Add `renderScale` field to `SettingsState` (default: `scale150`)
- [x] Add `setRenderScale()` method with SharedPreferences persistence
- [x] Add `render_scale` pref key (int index)

### 0.2 Add Thumbnail Management Setting (User-Controlled) ✅
- [x] Add `ThumbnailSource` enum: `auto`, `custom`, `regenerate`
- [ ] ~~Add "Regenerate Thumbnail" button in Series Detail / Settings~~ -> Phase 3.3
- [x] Add `ThumbnailService.regenerateThumbnail(seriesId, seriesPath)` method
- [x] Add custom cover support (`setCustomCover` method)
- [ ] ~~Expose thumbnail source in UI (show badge: "Auto" / "Custom")~~ -> Phase 3.3

### 0.3 Fix ALL Broken Settings Buttons ✅
**Root Cause:** `_showSettingsSheet()` uses local `setSheetState` only, doesn't call provider notifier methods.

| Button | Current | Fix |
|--------|---------|-----|
| Brightness Slider | Local var only | `setReadingBrightness()` |
| View Mode Grid | ~~Removed (only FitWidth)~~ | Simplified to info display |
| Scroll Mode Segmented | ~~Removed (only Vertical)~~ | Simplified to info display |
| Night Filter | No persist | `setDarkOverlay()` |
| Keep Screen On | No persist | `setKeepScreenOn()` |
| Auto Continue | No persist | `setAutoContinue()` |
| Reading Direction | Not wired | `setReadingDirection()` |
| Orientation Mode | Not wired | `setOrientationMode()` |

---

## Phase 1: Multi-Resolution PDF Renderer Core ✅

### 1.1 Update PdfRenderer for Multi-Resolution ✅
**File:** `lib/infrastructure/services/pdf_renderer.dart`

- [x] Add `RenderQuality` enum: `thumbnail (0.5x)`, `lowRes (1.0x)`, `highRes (dynamic per setting)`
- [x] Add `renderScale` field (from Settings) - default 1.5x
- [x] Restructure cache to 3-tier:
  ```dart
  _rawCacheThumbnail: LinkedHashMap<int, PdfPageImage>  // 20 pages max
  _rawCacheLowRes: LinkedHashMap<int, PdfPageImage>     // 15 pages max
  _rawCacheHighRes: LinkedHashMap<int, PdfPageImage>    // 8 pages max (1.5x/2.0x)
  _imageCache: LinkedHashMap<int, ui.Image>             // 8 pages max (high-res ready)
  ```
- [x] Update `_renderRawPage(int index, RenderQuality quality)` with scale param
- [x] Add `getPageImage(int index, RenderQuality quality)` method
- [x] Add `prefetchRange(start, end, quality)` for batch prefetch
- [x] Add `setRenderScale(scale)` - clears high-res cache, triggers re-render
- [x] Add memory guard: evict high-res when >150MB RSS

### 1.2 Background Low-Res Rendering via compute() ✅
- [x] Create top-level `_renderLowResIsolate(_RenderParams)` function
- [x] `_RenderParams`: filePath, pageIndex, scale (1.0x)
- [x] Add `prefetchLowResBackground(range)` using `compute()`
- [x] Note: High-res stays on main thread (async, non-blocking)

### 1.3 Thumbnail Integration ✅
- [x] `ThumbnailService._generateThumbnail()` renders at ~300px width (was full size)
- [x] Add `ThumbnailService.getThumbnailBytes(seriesId)` for instant access
- [x] Reader: use thumbnail as **instant first frame** (blur → low-res → high-res)

---

## Phase 2: Progressive Loading UI (Zero Blank Screen) ✅

### 2.1 Create _ProgressivePageImage Widget ✅
**File:** `lib/presentation/reader/pages/reader_page.dart`

**Visual States (NO BLANK SCREEN):**
```
State 0: Thumbnail (instant, blurred sigma 8)     → 0ms
State 1: Low-Res 1.0x (sharp, fade in 150ms)      → ~100ms
State 2: High-Res 1.5x/2.0x (cross-fade 300ms)    → ~300ms
```

- [x] Use `AnimatedSwitcher` for smooth transitions
- [x] `ImageFiltered` with `ImageFilter.blur(sigmaX: 8, sigmaY: 8)` for thumbnail
- [x] `FilterQuality.low` during blur for performance
- [x] Handle null/error states gracefully

### 2.2 Vertical Scroll Mode Refactor ✅
- [x] Replace `FutureBuilder` per item with `_ProgressivePageImage`
- [x] Pass `imageProvider` to progressive widget
- [x] Remove placeholder `Container(height: 400, spinner)` - **NEVER show blank**
- [x] Add `AutomaticKeepAliveClientMixin` for smooth scroll recycling

### 2.3 Scroll-Based Prefetch Logic ✅
- [x] Add `ScrollController` listener in `initState`
- [x] Calculate visible range: `firstVisible` to `lastVisible`
- [x] Prefetch window: `visible ± 3 pages` low-res via compute()
- [x] High-res upgrade for visible pages (debounced 2s idle)
- [x] Cancel prefetch for pages far from viewport

---

## Phase 3: Settings UI Fixes (All Buttons Working)

### 3.1 Fix Settings Bottom Sheet Wiring ✅
**File:** `reader_page.dart` - `_showSettingsSheet()`

**Brightness Slider:**
- [x] Wire to `setReadingBrightness(value)` directly
- [x] Remove local `brightness` variable

**View Mode Grid:**
- [x] **Simplified** - only FitWidth shown as info (no selection needed since only one mode)
- [x] Removed all non-fitWidth modes

**Scroll Mode:**
- [x] **Simplified** - only Vertical shown as info
- [x] Removed all non-vertical modes

**Display Toggles:**
- [x] ~~Dark Mode:~~ Removed (app is dark-only)
- [x] Night Filter: Wire to `setDarkOverlay(value ? 0.3 : 0)`
- [x] Keep Screen On: Wire to `setKeepScreenOn(value)`
- [x] Auto Continue: Wire to `setAutoContinue(value)`
- [x] Reading Direction: Wire to `setReadingDirection()`
- [x] Orientation: Wire to `setOrientationMode()`

### 3.2 Add Render Scale Setting to Reader Settings ✅
- [x] Add Radio button: "Render Quality" → 150% (Cepat) / 200% (Tajam)
- [x] Call `setRenderScale()` on change
- [x] Show current setting with checkmark

### 3.3 Add Thumbnail Management to Series Detail ✅
- [x] Add "Regenerate Cover" button in hero section
- [x] Add "Choose Custom Cover" (file picker)
- [x] Show thumbnail source badge: "Auto-generated" / "Custom"

### 3.4 Connect Settings Sheet to UI ✅
- [x] Replace unused "Search" icon in reader top bar with "Settings" gear icon
- [x] Wire top bar settings icon to `_showSettingsSheet()`
- [x] Controls auto-show on open + tap-to-toggle

---

## Phase 4: Performance Tuning & Testing

### 4.1 Memory Optimization 🔜
- [ ] Monitor RSS via `dart:developer` `ProcessInfo.currentRss`
- [ ] Hard cache limits: thumbnail=20, lowRes=15, highRes=8
- [ ] Aggressive eviction: LRU + distance from current page
- [ ] Target: <150MB peak for 60MB PDF

### 4.2 Benchmark Targets
| Metric | Target |
|--------|--------|
| First paint (page 1) | <200ms (thumbnail blur) |
| Next page on scroll | <50ms (low-res ready) |
| Full quality | <1.5s (bg upgrade) |
| Blank screen | **ZERO** |
| RAM peak (60MB PDF) | <150MB |
| 60fps scroll | No jank |

### 4.3 Test Scenarios 🔜
- [ ] Cold start: open 60MB webtoon PDF → first page visible <200ms
- [ ] Fast scroll: fling 50 pages → no blank frames
- [ ] Slow scroll: page by page → smooth transitions
- [ ] Chapter change: next chapter → preview instant
- [ ] Settings change: render scale 150%↔200% → re-render works
- [ ] Thumbnail regenerate: custom cover → shows immediately
- [ ] Memory pressure: open 5 large PDFs sequentially → no OOM

---

## Phase 5: Cleanup & Documentation

### 5.1 Remove Unused Code ✅
- [x] Remove `ReadingMode.horizontal`, `ReadingMode.single`, `ReadingMode.doublePage` (only vertical)
- [x] Remove `FitMode.fitHeight`, `FitMode.fitScreen`, `FitMode.original` (only fitWidth)
- [x] Remove horizontal/double-page render methods
- [x] Clean up unused fields/methods in reader_page.dart (`_isPageLoading`, `_disposeOffScreen`, `_onTapDown`, etc.)
- [x] Remove unused `isFitWidth` variable in settings_page.dart

### 5.2 Update Documentation 🔜
- [ ] Update `PROGRESS.md` with new phase
- [ ] Update `ISSUES.md` - close #15 (PDF loading UX), #16 (PDF loading slow)

---

---

## File Change Summary

| File | Phases | Description |
|------|--------|-------------|
| `settings_provider.dart` | 0 | RenderScale enum, thumbnail settings, fix all notifiers |
| `pdf_renderer.dart` | 1 | Multi-res cache, compute() low-res, prefetch API |
| `thumbnail_service.dart` | 1 | Regenerate API, 300px thumb, custom cover support |
| `reader_page.dart` | 2, 3 | Progressive widget, scroll prefetch, settings fixes |
| `series_detail_page.dart` | 3 | Thumbnail management UI |
| `app_router.dart` | - | Verify routes |

---

## Execution Order

```
Phase 0 (Settings Foundation) → Phase 1 (Renderer Core) → Phase 2 (Progressive UI)
    → Phase 3 (Settings Fixes) → Phase 4 (Tuning) → Phase 5 (Cleanup)
```

**Estimated Total:** ~12-15 hours

---

## Dependencies & Risks

| Risk | Mitigation |
|------|------------|
| `pdfx` not thread-safe | Low-res: new doc per isolate. High-res: main thread async. |
| Memory spike on large PDFs | Hard cache limits + RSS monitoring + aggressive eviction |
| Settings not persisting | Verify all notifiers call `_prefs.setXxx()` + `state = copyWith()` |
| Thumbnail race condition | Use `Future.microtask` + mounted checks |
| compute() overhead | Only for low-res (1.0x), high-res stays main thread |

---

## Acceptance Criteria

- [ ] Open 60MB webtoon → first content visible <200ms (blurred thumb)
- [ ] Scroll 100 pages → **zero blank frames**, smooth 60fps
- [ ] Settings: **ALL buttons work**, persist across restarts
- [ ] Render scale: 150%/200% toggle works, re-renders correctly
- [ ] Thumbnail: regenerate + custom cover both work
- [ ] RAM <150MB peak, no OOM on emulator/device
- [ ] `flutter analyze` = 0 errors
- [ ] All existing tests pass