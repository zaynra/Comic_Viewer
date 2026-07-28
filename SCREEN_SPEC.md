# Omnivious Reader — Screen Specification

## 1. Home Page (`home_page.dart`)

### Structure
```
Scaffold
└── folderState.when (libraryFolderNotifierProvider)
    ├── null → _FolderPicker (pilih folder pertama)
    └── path → _LibraryView
                └── Stack
                    ├── CustomScrollView
                    │   ├── _GlassTopBar (logo, title, add folder btn, search btn)
                    │   ├── _FilterTabs (pill-shaped horizontal tabs)
                    │   ├── content sliver (based on _selectedTab):
                    │   │   0 → _buildAllItemsSliver → _ShelfGrid
                    │   │   1 → _buildRecentSliver  → _ShelfGrid
                    │   │   2 → _buildFavoritesSliver → _ShelfGrid
                    │   │   3 → _buildVaultSliver   → _ShelfGrid (PIN protected)
                    │   └── SliverPadding (120px bottom space)
                    └── GlassBottomNav (Library / History / Settings)
```

### Tabs
| Index | Name | Provider | Description |
|-------|------|----------|-------------|
| 0 | All Items | `allSeriesProvider` | All non-vaulted series |
| 1 | Recent | `recentSeriesProvider` | Recently opened (limit 10) |
| 2 | Favorites | `favoriteSeriesProvider` | Favorited series |
| 3 | Vault | `_vaultFiles` (local state) | PIN-protected (PIN: 2305) |

### _ShelfGrid (Shelf Layout)
- `SliverList` with rows of 2 books per row
- Each row: `SizedBox(height: (screenW - padding*2 - spacing) / 2 * 1.5)`
- After each row: **shelf divider** (6px tall container with shadow + border-top white10)
- `_BookCard` is a full-bleed cover with gradient overlay at bottom
- Gradient: transparent → black 0.2 → black 0.8 (80px height)
- Title + progress bar (3px) + percentage overlaid at bottom
- `_BookCard` has rounded corners + boxShadow (black 0.5, blur 12, offset 0,4)

### _GlassTopBar
- Logo image (32x32, `assets/images/or_logo.png`)
- Title "Omnivious Reader" (font 22, w600)
- Spacer → `IconButton` add folder (Icons.create_new_folder_outlined) → search (Icons.search)
- `onAddFolder` callback → `_addFolderToLibrary()` uses FilePicker + scanFolder + invalidate providers

### Vault — Flat PDF Mode (Berbeda dari Library)
Vault **tidak** menggunakan model Series/Chapter seperti tab All Items. Vault scan folder langsung untuk file `*.pdf` dan menampilkan setiap PDF sebagai item individual di shelf grid.

**Perbedaan dengan Library:**
| Aspek | Library (All Items) | Vault |
|-------|---------------------|-------|
| Data model | Series → Chapters | Langsung PDF files |
| Display | Per-series (folder) | Per-file (individual) |
| Tap → | Series Detail page | Reader langsung |
| Scan | `scanNotifier` → DB | `dir.listSync()` langsung |
| Storage | SQLite Series/Chapters | SharedPreferences (path only) |

**Data Flow:**
```
User pilih folder vault
  → FilePicker → simpan path ke SharedPreferences key 'vault_folder_path'
  → Directory(folder).listSync(recursive: true) filter *.pdf
  → Sort by name natural
  → Tampilkan di _VaultGrid (2-column shelf)
  → Tap → buat Chapter(id:0, seriesId:0, name, filePath) → pushNamed('reader', extra: chapter)
```

**Vault Access:**
- Tab Vault index 3 requires PIN
- PIN dialog: 4-digit input, each digit separate TextField, auto-focus next
- PIN: `2305` (hardcoded)
- Success: `_vaultUnlocked = true`, switch to tab 3
- Failure: clear all, show "PIN salah", reset focus to first digit
- `_pickVaultFolder()`: simpan path ke SharedPrefs + scan PDF langsung (tanpa scanNotifier)
- `_vaultFiles` state: List of `_VaultFile` objects (name + path), di-load otomatis di initState
- `_VaultItemCard`: PDF thumbnail (via `vaultThumbnailProvider`), gradient overlay + nama file, tap → reader
- `_loadVaultFolder()`: baca SharedPrefs → scan ulang setiap app restart

### Empty States
- All Items: `_EmptyState` with book icon + "Tidak ada series ditemukan" + "Pindai Ulang" button
- Recent: history icon + "Tidak ada aktivitas terbaru"
- Favorites: heart icon + "Belum ada favorit"
- Vault: lock icon + "Vault kosong" + "Pilih Folder untuk Vault" button (muncul hanya jika `_vaultFiles` kosong)

---

## 2. Reader Page (`reader_page.dart`)

### Structure
```
Scaffold
└── Stack
    ├── GestureDetector (toggle controls visibility)
    │   └── NotificationListener<ScrollNotification>
    │       └── InteractiveViewer
    │           └── Column
    │               └── for each page → _ProgressivePageImage
    ├── _controlsOverlay (top bar + bottom bar, visibility toggled)
    │   ├── Top bar: back button, chapter title
    │   └── Bottom bar: [Prev] [All Files] [Settings] [Next]
    └── (when visible)
        └── _settingsSheet (bottom sheet)
```

### Progressive Loading (_ProgressivePageImage)
- Phase 0: blurry thumbnail (0.5x scale)
- Phase 1: lowRes (1.0x scale) — replaces thumbnail
- Phase 2: highRes (1.5x or 2.0x) — replaces lowRes after 2s idle
- Each phase clones the image to avoid "disposed image" crash

### Controls
- Tap anywhere → toggle _showControls
- Controls auto-hide after 3s (Timer)
- Bottom bar buttons:
  - `[Prev]` (navigate_before) → previous page, disabled if first
  - `[All Files]` (menu) → `_showChapterList()` scans parent folder for all PDFs
  - `[Settings]` (settings) → `_showSettingsSheet()` bottom sheet
  - `[Next]` (navigate_next) → next page, disabled if last

### Settings Sheet
- Render Scale: Radio buttons 100% (Normal) / 150% (Cepat) / 200% (Tajam)
- Brightness: Slider (0.3 - 1.0)
- Night Filter: Switch (orange overlay, 0-50%)
- Keep Screen On: Switch
- Auto Continue: Switch
- Direction: LTR / RTL toggle
- Orientation: Portrait / Landscape toggle

### PDF Renderer (`pdf_renderer.dart`)
- 3-tier quality: thumbnail (0.5x), lowRes (1.0x), highRes (1.5x-2.0x)
- 3 separate caches (LinkedHashMap) + 1 unified imageCache (with compound key `"$index_${quality.index}"`)
- Low-res background via `compute()` isolate (fallback main thread)
- Prefetch range: visible ±2 at lowRes
- HighRes upgrade: after 2s idle Timer
- Cache eviction: LRU with max limits (thumb 20, low 15, high 8)
- Memory monitor: Timer every 10s, `checkMemoryPressure()`

---

## 3. History Page (`history_page.dart`)

### Structure
```
Scaffold
└── SafeArea
    └── Stack
        ├── Column
        │   ├── GlassAppBar ("Recent Activity" + back button + search)
        │   └── Expanded
        │       └── historyAsync.when (historyProvider)
        │           ├── empty → icon + "No recent activity"
        │           └── ListView grouped by date label
        │               └── _HistoryCard per item
        └── GlassBottomNav (Library / History / Settings)
```

### History Groups
- Grouped by label (e.g. "Today", "Yesterday", "This Week")
- Each item: cover image, series name, chapter title, timestamp
- Tap → navigate to reader page with that chapter

---

## 4. Series Detail Page (`series_detail_page.dart`)

### Structure
```
Scaffold
└── Consumer
    └── CustomScrollView
        ├── _HeroHeader (SliverAppBar: cover thumbnail, blurred bg, series name/author/desc)
        ├── _MetadataSection (favorite toggle, resume btn, bookmark, more menu)
        ├── _ActionButtons ("Lanjut Baca" + "Baca dari Awal")
        ├── "Recent Chapters" header + Sort button
        └── _ChapterList (chaptersAsync.when)
```

### _ChapterItem
- Thumbnail placeholder (48x64) with badge `#${chapter.sortOrder}`
- Chapter name (max 1 line, ellipsis)
- **`${chapter.totalPages} Pages`** — page count dari PDF (via `_getPdfPageCount`)
- Progress bar + percentage (if active/in-progress)
- Status icon: `download_done` (read), `download` (unread), `play_arrow` (in-progress)
- Tap → `pushNamed('reader', extra: chapter)`

### Overflow Menu (More)
- **Vault/Pindah ke Vault** — toggle `isVaulted`
- **Edit Cover** — `_showCoverOptions()`: Regenerate, Choose Custom, Remove
- **Hapus Series** — konfirmasi dialog, cascade delete chapters + series, pop back

### CRITICAL BUG HISTORY — JANGAN TERULANG

#### Bug: Folder Import Tidak Mendeteksi PDF Setelah Hapus Series

**Root Cause Chain:**

1. **`deleteSeries()` tidak hapus chapters** (`series_repository_impl.dart:53`)
   - Dulu: `DELETE FROM series WHERE id = ?` saja
   - Chapters jadi orphaned (series_id mengarah ke id yang sudah dihapus)
   - **Fix:** `DELETE FROM chapters WHERE series_id = ?` SEBELUM `DELETE FROM series`

2. **`Chapter.==` hanya compare `id` + `filePath`** (`chapter.dart:77`)
   - Scanner sudah punya logic update `seriesId` di `_scanSeriesFolder`:
     ```dart
     final updatedChapter = chapter.copyWith(seriesId: series.id);
     if (updatedChapter != chapter) {  // <— SELALU FALSE karena == tidak cek seriesId
       await _chaptersRepository.updateChapter(updatedChapter);
     }
     ```
   - **Fix:** Tambah `other.seriesId == seriesId` ke operator `==`

3. **`_addStandalonePdf` tidak punya `else` clause** (`library_scanner.dart:163`)
   - Untuk folder flat (PDF tanpa subfolder di dalamnya), chapter yatim tidak pernah di-update
   - **Fix:** Tambah `else { updated = chapter.copyWith(seriesId: series.id); updateChapter(updated); }`

**Safety Net:**
```
deleteOrphanedChapters() → DELETE FROM chapters WHERE series_id NOT IN (SELECT id FROM series)
```
Dipanggil di awal setiap `scanFolder()`.

**TL;DR:** Setiap hapus series, cascade hapus chapters dulu. Setiap scan, cleanup orphaned chapters. Jangan pernah lupa update `seriesId` saat update chapter.

---

### CRITICAL BUG — JANGAN TERULANG

#### Bug: Overflow 43px pada "Lanjutkan Membaca"

**Penyebab:** Tombol `PrimaryButton` dengan icon + text `"Lanjutkan Membaca"` terlalu lebar untuk `Row` yang sempit.

**Fix:**
```dart
// SEBELUM (overflow):
PrimaryButton(label: 'Lanjutkan Membaca', icon: Icons.play_arrow, ...)

// SESUDAH (fix):
PrimaryButton(label: 'Lanjut Baca', ...)  // tanpa icon, text pendek
```

---

## 5. Settings Page (`settings_page.dart`)

### Structure
```
Scaffold
└── Consumer
    └── CustomScrollView
        ├── SliverAppBar ("Pengaturan" = Settings)
        └── SliverList of settings tiles
```

### Settings Items
- **Render Scale**: radio 100% (Normal) / 150% (Cepat, DEFAULT) / 200% (Tajam)
  - ⚠️ Default harus 150% (index 1), JANGAN ubah ke 100% — menyebabkan kualitas jelek
- **Brightness**: slider
- **Night Filter**: slider 0-50%
- **Keep Screen On**: switch
- **Auto Continue**: switch
- **Direction**: LTR / RTL radio
- **Orientation**: Portrait / Landscape radio
- **About**: version info

---

## 6. Splash Page (`splash_page.dart`)

### Structure
```
Scaffold
└── Stack
    ├── AnimatedBuilder (rotation animation)
    │   └── OR logo image (rotating 360° slowly)
    └── Positioned loading text at bottom ("Memuat...")
```

### Behavior
- Auto-navigate to home after 2.5s
- Uses `TickerProviderStateMixin` for animation
- Logo asset: `assets/images/or_logo.png`
- Background: AppColors.surfaceContainerLowest (#060E20)

---

## 7. Shared Widgets

### GlassBottomNav (`glass_bottom_nav.dart`)
- Floating pill shape with BackdropFilter blur
- Returns `Positioned` (must be inside a `Stack`)
- Items: icon + label (label only visible when active)
- Active state: primaryContainer + primary color
- Inactive: onSurfaceVariant icon only

### PrimaryButton (`widgets.dart`)
- Filled button with primary color
- Icon + label layout
- Rounded corners (AppRadius.lg)
- Busy state: CircularProgressIndicator
- ⚠️ JANGAN gunakan icon untuk button di Row sempit — bisa overflow

### Glassmorphism Pattern
```dart
ClipRRect(
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
    child: Container(
      color: AppColors.surface.withValues(alpha: 0.8),
      border: Border.all(color: AppColors.glassBorderSubtle),
    ),
  ),
)
```

---

## Data Flow

### Providers
```
libraryFolderNotifierProvider → pick folder → save SharedPreferences
allSeriesProvider → SeriesRepository.getAllSeries() (WHERE is_vaulted = 0)
vaultedSeriesProvider → SeriesRepository.getVaultedSeries()
recentSeriesProvider → RecentRepository.getRecentSeries(limit: 10)
favoriteSeriesProvider → FavoritesRepository.getFavoriteSeries()
scanNotifierProvider → LibraryScanner.scanFolder(folderPath)
chaptersBySeriesProvider → ChaptersRepository.getChaptersBySeriesId(id)
thumbnailBySeriesProvider → ThumbnailService.getThumbnail(id, path)
vaultThumbnailProvider → ThumbnailService.getVaultThumbnail(filePath)
```

### Provider Invalidation Flow
```
scanFolder() selesai
  → scanNotifierProvider state = AsyncData(ScanResult)
  → listener di _LibraryView: invalidate allSeriesProvider, recentSeriesProvider, vaultedSeriesProvider
  → UI rebuild dengan data baru
```

### LibraryScanner Flow
```
scanFolder(path)
  1. deleteOrphanedChapters() ← safety net: hapus semua chapter tanpa parent series
  2. listSync(recursive: false) root folder
  3. For each entity:
     a. Directory → _scanSeriesFolder(dir)
        → _findPdfFiles(dir) — recursive: false, tapi rekursif ke subdir
        → create/update Series (path sebagai key)
        → create/update Chapters (file_path sebagai key, sort_order dari MetadataParser)
        → totalPages dari _getPdfPageCount() — buka PDF via pdfx
     b. File (PDF) → _addStandalonePdf(file)
        → series: parent directory sebagai series
        → sortOrder: dari MetadataParser.parseSortOrder atau existingChapters.length + 1
        → totalPages dari _getPdfPageCount()
```

### Database Migrations (`app_database.dart`)
- v1: initial schema (series, chapters, library_index, reading_progress)
- v2: CREATE reading_progress (migration)
- v3: CREATE thumbnails
- v4: CREATE favorites, recent, index recent
- v5: ALTER series ADD COLUMN author, description, genres
- v6: CREATE bookmarks, index bookmarks
- v7: ALTER series ADD COLUMN is_vaulted INTEGER DEFAULT 0 (try-catch)

### Critical SQLite Rules
1. `series.path` UNIQUE — jangan insert duplicate path
2. `chapters.file_path` UNIQUE — jangan insert duplicate file path
3. FOREIGN KEY constraints TIDAK di-enforce (sqflite default) — manual cascade wajib
4. `deleteSeries()` HARUS cascade: hapus chapters dulu, baru series
5. `Chapter.==` HARUS include `seriesId` — agar dirty check di scanner bekerja

### Series Entity
```dart
class Series {
  final int id;
  final String name;
  final String path;
  final bool isVaulted;
  // ... copyWith, toMap, fromMap
  // == operator: id + path (tidak perlu include field lain)
}
```

### Chapter Entity
```dart
class Chapter {
  final int id;
  final int seriesId;
  final String name;
  final String filePath;
  final int sortOrder;      // dari MetadataParser.parseSortOrder()
  final int totalPages;     // dari _getPdfPageCount(), jangan default 0
  final int currentPage;
  final bool isRead;
  // == operator: id + seriesId + filePath (HARUS include seriesId!)
}
```
