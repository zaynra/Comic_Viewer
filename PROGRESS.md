# Omnivious Reader - Development Progress

## Current Phase: Phase 12 — Critical Bug Fixes ✅

---

## Phase 0 — Skeleton ✅
**Completed:** 2026-07-24

- Initialized Flutter project with Clean Architecture folder structure
- Setup Riverpod, GoRouter, dark theme with lavender accent (`#CFBCFF`)
- SAF folder picker via `file_picker`, SharedPreferences for persistence
- Fixed NDK version mismatch (upgraded to 27.0.12077973)
- Generated Android platform files via `flutter create .`

---

## Phase 1 — Data Layer & Library Scanner ✅
**Completed:** 2026-07-24

- SQLite schema: `series`, `chapters`, `library_index`
- Domain entities, repositories, recursive library scanner
- Natural sort for chapter names (Chapter_0001 → Chapter_0002)

---

## Phase 2 — Library UI + Series Detail ✅
**Completed:** 2026-07-24

- Grid view (2-column) with series name and chapter count
- Series Detail: hero cover + gradient overlay, chip badges, chapter list
- Chapter cards show progress bar (in-progress) or check_circle (completed)
- UI-only "Mulai Baca" + "Baca dari Awal" buttons

---

## Phase 2b — Reader UI Shell & Settings UI Shell ✅
**Completed:** 2026-07-24

- Reader page shell with overlay UI (top bar, bottom controls, slider)
- Settings page with sections (Tampilan, Membaca, Penyimpanan, Tentang)

---

## Phase 3 — Reader Core ✅
**Completed:** 2026-07-24

- Integrated `pdfx` for PDF rendering
- LRU cache (5 pages), page-by-page async render
- Tap left/right thirds for page navigation, pinch zoom (0.5x–3x)
- Page slider for quick navigation
- Error handling for corrupted/missing PDFs

---

## Phase 4 — Reading Progress ✅
**Completed:** 2026-07-24

- `reading_progress` table (chapter_id, current_page, zoom_level)
- Save/restore progress on page change and dispose
- "Lanjutkan Membaca" section on HomePage

---

## Phase 5 — Chapter Navigation ✅
**Completed:** 2026-07-24

- Prev/Next chapter buttons (disabled at edges)
- Auto-next dialog at last page (5-second countdown)
- Chapter cards in Series Detail open Reader on tap

---

## Phase 6 — Cover & Thumbnail ✅
**Completed:** 2026-07-24

- `thumbnails` table (series_id, source, file_path)
- Custom cover detection (cover.jpg, thumb.png, etc.)
- Auto-generate from PDF first page (saved to `.thumbnails/`)
- Thumbnail display in grid and series detail

---

## Phase 7 — Search, Favorites, Recent ✅
**Completed:** 2026-07-24

- `favorites` and `recent` tables
- Realtime search by series name
- Favorites toggle with persistence
- Recent tracking (auto on chapter open)

---

## Phase 8 — Incremental File Monitoring ✅
**Completed:** 2026-07-24

- `watcher` package for file system monitoring
- Debounced change detection (2-second delay)
- Auto-add new PDFs, auto-remove deleted PDFs
- Cleanup empty series after file removal

---

## Phase 9 — Settings & Polish ✅
**Completed:** 2026-07-24

- Theme mode selection (Terang/Gelap/Sistem) with persistence
- Reading direction settings (Kiri ke Kanan/Kanan ke Kiri/Vertikal)
- Keep screen on toggle
- Custom `PdfLoadException` for better error handling
- Retry button and back navigation on PDF load errors

---

## Phase 10 — Metadata JSON Import ✅
**Completed:** 2026-07-24

- `MetadataParser` service for JSON metadata parsing
- Series metadata: title, author, artist, description, genres, language, year
- Chapter metadata: title, volume, chapter, language, pages
- Auto-parse `metadata.json` in series folder
- Auto-parse `Chapter_XXXX.json` for individual chapters
- Database schema v5: added author, description, genres columns to series

---

## Phase 11 — Vault Flat PDF Mode & Performance Fixes ✅
**Completed:** 2026-07-28

### Vault Flat PDF Mode
- Vault scan folder langsung untuk `*.pdf` (bukan Series/Chapter model)
- Setiap PDF = 1 item shelf (`_VaultItemCard`), tap → reader langsung
- Vault folder path disimpan di SharedPreferences, auto-load di initState
- Tab All Items / Recent / Folders tetap pakai model Series/Chapter — tidak berubah

### Render Scale
- Tambah opsi `100% (Normal)` sebagai default
- Wiring: setting sekarang benar-benar memanggil `_renderer.setRenderScale()`

### Slow Loading Fixes
- `cacheExtent: 800` di ListView.builder — widget dibuat lebih awal
- 3 fase loading concurrent (thumbnail/lowRes/highRes start bersamaan)
- Thumbnail prefetch di initial pages + scroll-based prefetch
- Fix `prefetchHighRes` key bug (`_imageCache.containsKey(index)` → `_cacheKey(index, RenderQuality.highRes)`)
- Estimasi awal `_avgPageHeight` pakai `screenWidth * 1.4` — scroll prefetch tidak delay

---

## Phase 11b — All TODO Items (Search, Favorite, Bookmark, dll) ✅
**Completed:** 2026-07-28

### Search (3 lokasi)
- Home page: Icon search di-wire ke search dialog + `searchQueryProvider`
- Series Detail: search icon terhubung melalui home search
- History: GestureDetector + inline search dialog dengan `searchQueryProvider`

### Favorite
- Series Detail: Heart toggle (filled/outlined) dengan `favoriteSeriesProvider` + `isFavoriteProvider`
- Home: Favorites tab (index 2, vault geser ke index 3) dengan `_buildFavoritesSliver()`

### Bookmark
- Series Detail: `bookmark_add` icon → dialog input nama bookmark + `addBookmark()` call via `bookmarkRepositoryProvider`

### Overflow Menu (2 lokasi)
- Series Detail: `more_vert` → bottom sheet: Vault toggle, Edit Cover, Hapus Series
- Thumbnail Viewer: `more_vert_rounded` → GestureDetector + bottom sheet opsi

### Sort
- Series Detail: `Icons.sort` → bottom sheet pilihan Urutkan (Nomor ASC / Nomor DESC)

### Settings — Interactive Controls
- View Mode: Dari teks "Active" → GestureDetector + bottom sheet pilih `FitMode` (fitWidth, fitHeight, fitBoth)
- Scroll Mode: Dari teks "Active" → GestureDetector + bottom sheet pilih `ReadingMode` (horizontalLTR, horizontalRTL, vertical)
- Info Tiles: Version + Built with → AlertDialog informasi detail

### _ActionButtons (Dead Widget Revival)
- Dari `SizedBox.shrink()` → dua tombol: "Lanjutkan Membaca" (resume) + "Baca dari Awal"

### Thumbnail Viewer Icons
- Settings icon → GestureDetector + bottom sheet (Regenerate Thumbnails)
- More icon → GestureDetector + bottom sheet (Detail File)

---

## Phase 12 — Critical Bug Fixes ✅
**Completed:** 2026-07-28

### Bug 1: Folder Import Tidak Mendeteksi PDF (ORPHANED CHAPTERS)

**Gejala:** Setelah "Hapus Series", folder yang sama di-import ulang → series muncul tapi chapters kosong.

**Akar Masalah (3 bugs berantai):**

1. **`deleteSeries` tidak cascade hapus chapters** (`series_repository_impl.dart:53`)
   - Hanya hapus dari tabel `series`, chapters tetap yatim (orphaned) di DB
   - Fix: `db.delete('chapters', WHERE series_id = ?)` sebelum `db.delete('series', ...)`

2. **`Chapter.==` operator hanya compare `id` + `filePath`** (`chapter.dart:77`)
   - Scanner sudah punya `else` clause untuk update `seriesId` chapter yatim
   - Tapi karena `==` tidak include `seriesId`, `updatedChapter != chapter` selalu false
   - Fix: Tambah `other.seriesId == seriesId` ke operator `==`

3. **`_addStandalonePdf` tidak punya `else` clause** (`library_scanner.dart:160`)
   - Untuk folder flat (PDF langsung tanpa subfolder), chapter yatim tidak pernah di-update
   - Fix: Tambah `else` block dengan `copyWith(seriesId: series.id) + updateChapter`

**Safety Net:**
- `deleteOrphanedChapters()` method baru → `DELETE FROM chapters WHERE series_id NOT IN (SELECT id FROM series)`
- Dipanggil di awal `scanFolder()` — jamin tidak ada orphaned chapters

**Files changed:**
- `lib/data/repositories/series_repository_impl.dart` — cascade delete chapters
- `lib/domain/entities/chapter.dart` — `==` include `seriesId`
- `lib/infrastructure/services/library_scanner.dart` — `_addStandalonePdf` else clause + orphan cleanup
- `lib/domain/repositories/chapters_repository.dart` — `deleteOrphanedChapters()` interface
- `lib/data/repositories/chapters_repository_impl.dart` — `deleteOrphanedChapters()` implementation

---

### Bug 2: Overflow 43px pada "Lanjutkan Membaca" Button

**Gejala:** Di Series Detail, tombol "Lanjutkan Membaca" overflow karena icon + text terlalu besar untuk Row.

**Fix:**
- Hapus icon dari `PrimaryButton`
- Pendekkan label dari "Lanjutkan Membaca" → "Lanjut Baca"

**File changed:** `lib/presentation/series_detail/pages/series_detail_page.dart`

---

### Bug 3: Kualitas PDF Sangat Jelek

**Gejala:** Setelah render scale default diubah ke 100%, kualitas PDF turun drastis.

**Akar Masalah:** Render scale default diubah ke index 0 (100%) saat menambahkan opsi "100% (Normal)". Seharusnya tetap default 150%.

**Fix:** Kembalikan default ke index 1 (150%).

**File changed:** `lib/presentation/settings/providers/settings_provider.dart:124`

---

### Bug 4: Total Pages Selalu 0

**Gejala:** Di Series Detail, setiap chapter menampilkan "0 Pages".

**Akar Masalah:** Method `_getPdfPageCount()` dihapus dari `LibraryScanner` saat migrasi dari backup. `totalPages` selalu default 0.

**Fix:** Restore `_getPdfPageCount()` — buka PDF via `PdfDocument.openFile()` untuk dapat page count asli.

**File changed:** `lib/infrastructure/services/library_scanner.dart`

---

### Bug 5: Nomor Chapter Selalu #1

**Gejala:** Semua chapter di Series Detail menampilkan badge "#1".

**Akar Masalah:** `_addStandalonePdf` selalu pakai `sortOrder: 1` untuk semua chapter.

**Fix:** Hitung `sortOrder` dari `MetadataParser.parseSortOrder()` + jumlah chapters existing + 1.

**File changed:** `lib/infrastructure/services/library_scanner.dart`

---

## Post-MVP Fixes

### Manual Path Input (SAF Bypass)
**Completed:** 2026-07-24

**Issue:** Android 11+ SAF (Storage Access Framework) memblokir akses ke folder tertentu seperti `/sdcard/Download/` dan `/sdcard/`. Error: "Can't use this folder — To protect your privacy, choose another folder"

**Fix:**
- Added "Masukkan Path Manual" button on folder picker screen
- Dialog input for direct path entry (e.g., `/sdcard/Comics`)
- Added `setFolderPath()` method to `LibraryFolderNotifier`
- Files pushed via `adb push` to emulator are directly accessible via manual path

**Files changed:**
- `lib/presentation/home/pages/home_page.dart` — added `_FolderPicker` manual input button, `_showManualInputDialog` in HomePage
- `lib/presentation/home/providers/library_folder_providers.dart` — added `setFolderPath()` method

**How to use:**
1. Push test files: `adb push test_comics/ /sdcard/Comics/`
2. Open app → tap "Masukkan Path Manual"
3. Enter `/sdcard/Comics`
4. App scans and shows library

---

## SQLite Schema (v7 — Final)

```sql
series: id, name, path (UNIQUE), cover_path, author, description, genres, is_vaulted, created_at
chapters: id, series_id (FK), name, file_path (UNIQUE), sort_order, total_pages, current_page, is_read
library_index: id, folder_path (UNIQUE), last_scanned_at (unused)
reading_progress: id, chapter_id (FK, UNIQUE), current_page, zoom_level, last_opened_at
thumbnails: id, series_id (FK, UNIQUE), source, file_path, created_at
favorites: id, series_id (FK, UNIQUE), created_at
recent: id, series_id (FK), last_opened_at (indexed)
bookmarks: id, chapter_id (FK), page, note, created_at, UNIQUE(chapter_id, page)
```

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
| google_fonts | ^6.2.1 | Inter font |
| material_symbols_icons | ^4.2719.3 | Material Symbols icons |
| path | ^1.8.0 | Path manipulation |

---

## Test Files

Test files pushed to emulator at `/sdcard/Comics/`:

```
/sdcard/Comics/
├── Sample/
│   ├── Chapter_0001.pdf
│   ├── Chapter_0002.pdf
│   ├── Chapter_0001.json
│   └── metadata.json
└── Manga/
    ├── Chapter_0001.pdf – Chapter_0005.pdf
    └── metadata.json
```

---

## Notes
- UI text kept in Indonesian per user preference
- `rendering/` folder kept empty for future phases
- `permission_handler` reserved for later use
- Tests skipped (placeholder only)
