# Comic Viewer — Issue Log

## Last Updated: 2026-07-25 16:45 WIB

---

## CRITICAL: Functional Bugs (Current — Branch: desain)

---

### Issue #10: Filter Tabs Not Functional
**Status:** OPEN
**Date:** 2026-07-25
**Severity:** High

**Description:**
Home page filter tabs (All Items / Folders / Recent / Favorites) are UI-only. Tapping any tab does nothing — the content does not change.

**Expected:**
- "All Items" → shows all series
- "Folders" → shows folder-based view
- "Recent" → shows recently opened series
- "Favorites" → shows favorited series

**Root Cause:**
Tab tap handlers are wired but no filtering logic is implemented.

---

### Issue #11: Recent Activity / History Not Working
**Status:** OPEN
**Date:** 2026-07-25
**Severity:** High

**Description:**
History page shows "No recent activity" even after reading chapters. The `historyProvider` does not load data.

**Expected:**
After opening a chapter, it should appear in History grouped by Today/Yesterday/Older.

**Root Cause:**
Reading history is not being saved to DB when a chapter is opened. `_saveProgress` in ReaderPage may not be called, or the `recent` table is not being populated on chapter open.

---

### Issue #12: Chapter Shows "0 Pages"
**Status:** OPEN
**Date:** 2026-07-25
**Severity:** Medium

**Description:**
Series Detail page shows "0 Pages" for each chapter, even though the PDF has 5 pages.

**Expected:**
Show actual page count from PDF (e.g., "5 Pages").

**Root Cause:**
`total_pages` field in `chapters` table is not being populated during scan. The scanner reads PDF but doesn't store page count.

---

### Issue #13: Unnecessary Download Button
**Status:** OPEN
**Date:** 2026-07-25
**Severity:** Low

**Description:**
Each chapter row in Series Detail has a download icon button. Since all files are local PDFs, download is meaningless.

**Fix:**
Remove the download button from chapter list items.

---

### Issue #14: Reader Menu Bar Not Visible
**Status:** OPEN
**Date:** 2026-07-25
**Severity:** Critical

**Description:**
When opening a PDF, the reader menu bar (top bar + bottom controls) is hidden by default. User must tap to reveal it. There is no visible way to navigate between chapters or access settings without knowing to tap.

**Expected:**
Controls should be visible by default when entering reader, OR there should be a persistent navigation hint.

**Note:**
The controls DO exist — they toggle via `_showControls`. But initial state is `false` (hidden). User reports they cannot see any controls.

---

### Issue #15: PDF Loading Shows Spinner on Empty Screen
**Status:** OPEN
**Date:** 2026-07-25
**Severity:** High

**Description:**
When loading a PDF, the user sees a blank dark screen with a small spinner in the center. No visual indication of progress. Can take several seconds for webtoon-style PDFs.

**Expected:**
Progressive loading: show a blurred preview first, then sharpen as full resolution renders. OR at minimum show loading progress.

**Root Cause:**
`_isLoading = true` shows a centered `CircularProgressIndicator` with no context. PDF rendering is async and takes time for large files.

---

### Issue #16: PDF Loading Too Slow
**Status:** OPEN
**Date:** 2026-07-25
**Severity:** Medium

**Description:**
Webtoon-style PDFs (20-40MB, very tall pages) take 5-10 seconds to show first page. During this time, only a spinner is visible.

**Expected:**
- Faster initial render (lower resolution placeholder)
- Progressive sharpening (low-res → high-res)
- OR: show first page in low quality immediately, refine in background

---

## FIXED Issues (Branch: desain)

---

### Issue #7: Gray Screen on Launch
**Status:** FIXED (2026-07-25)
**Severity:** Critical

**Description:**
App showed splash logo then gray screen. No content loaded.

**Root Cause:**
`GoogleFonts.getFont('Geist')` throws exception offline. `Inter` font fails DNS lookup.

**Fix:**
- Removed `GoogleFonts` dependency from `app_text_styles.dart` and `app_theme.dart`
- Using system `Roboto` font instead

---

### Issue #8: FlexParentData Cast Error
**Status:** FIXED (2026-07-25)
**Severity:** Critical

**Description:**
`type 'FlexParentData' is not a subtype of type 'StackParentData'` crash on launch.

**Root Cause:**
`GlassBottomNav` returned a `Positioned` widget, but was used inside a `Column` in HistoryPage. `Positioned` only works inside `Stack`.

**Fix:**
- Changed `GlassBottomNav` from `Positioned` to `Padding`
- Wrapped in `Positioned` only in home page's `Stack`

---

### Issue #9: PDF Shows as Tiny Thin Lines
**Status:** FIXED (2026-07-25)
**Severity:** Critical

**Description:**
PDF pages rendered as very narrow strips (~60px wide) on full screen, impossible to read.

**Root Cause:**
Default `fitMode` was `fitScreen` which scales to fit both width AND height. For tall webtoon pages, the height constraint dominates, making images tiny.

**Fix:**
- Default `fitMode` → `fitWidth` (fills screen width)
- Default `readingMode` → `vertical` (webtoon scroll)
- Fixed SharedPreferences defaults (index 2=vertical, 1=fitWidth)
- Render resolution 1.5x → 2.0x

---

## OLD Issues (Original implementation)

---

### Issue #1: Scanner Shows 0 Series Despite Files Present
**Status:** FIXED (2026-07-24)

Android 11+ Scoped Storage blocked `dart:io` access. Fixed with manual path input and `MANAGE_EXTERNAL_STORAGE` permission via `appops set`.

---

### Issue #2: permissions_handler Not Recognizing Permission
**Status:** FIXED (2026-07-24)

Used `appops set` command as workaround instead of relying on permission_handler.

---

### Issue #4: SAF Blocks Folder Access on Android 11+
**Status:** FIXED (2026-07-24)

Added "Masukkan Path Manual" button for direct path entry.

---

## Test Results (2026-07-25)

| Test | Result | Notes |
|------|--------|-------|
| App launches without crash | ✅ | |
| PDF opens (5-page chapter) | ✅ | |
| PDF renders fit-to-width | ✅ | Vertical scroll, fills screen width |
| Filter tabs work | ❌ | UI only, no filtering logic |
| History/Recent activity | ❌ | Not tracking reading activity |
| Chapter page count | ❌ | Shows "0 Pages" |
| Reader controls visible on open | ❌ | Hidden by default, user must tap |
| PDF loading UX | ❌ | Spinner only, no progressive loading |
| Download button | ❌ | Unnecessary for local files |
