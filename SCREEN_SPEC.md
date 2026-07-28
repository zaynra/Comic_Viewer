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
                    │   │   2 → _buildVaultSliver   → _ShelfGrid (PIN protected)
                    │   └── SliverPadding (120px bottom space)
                    └── GlassBottomNav (Library / History / Settings)
```

### Tabs
| Index | Name | Provider | Description |
|-------|------|----------|-------------|
| 0 | All Items | `allSeriesProvider` | All non-vaulted series |
| 1 | Recent | `recentSeriesProvider` | Recently opened (limit 10) |
| 2 | Vault | `vaultedSeriesProvider` | PIN-protected (PIN: 2305) |

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
- Tab Vault index 2 requires PIN
- PIN dialog: 4-digit input, each digit separate TextField, auto-focus next
- PIN: `2305` (hardcoded)
- Success: `_vaultUnlocked = true`, switch to tab 2
- Failure: clear all, show "PIN salah", reset focus to first digit
- `_pickVaultFolder()`: simpan path ke SharedPrefs + scan PDF langsung (tanpa scanNotifier)
- `_vaultFiles` state: List of `_VaultFile` objects (name + path), di-load otomatis di initState
- `_VaultItemCard`: icon PDF, gradient overlay + nama file, tap → reader
- `_loadVaultFolder()`: baca SharedPrefs → scan ulang setiap app restart

### Empty States
- All Items: `_EmptyState` with book icon + "Tidak ada series ditemukan" + "Pindai Ulang" button
- Recent: history icon + "Tidak ada aktivitas terbaru"
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
- Render Scale: Radio buttons 150% (Cepat) / 200% (Tajam)
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
    └── Stack
        ├── CustomScrollView
        │   ├── SliverAppBar (series name, back button)
        │   ├── SliverToBoxAdapter
        │   │   └── Cover image (with edit overlay icon)
        │   ├── SliverToBoxAdapter
        │   │   └── Series info + vault toggle button (lock/unlock)
        │   └── SliverList of chapters
        └── Edit cover bottom sheet (triggered by tap on cover)
```

### Features
- Thumbnail management: tap cover → bottom sheet
  - "Regenerate from PDF" → delete + regenerate
  - "Choose Custom Image" → FilePicker image
  - "Remove Custom Cover" → delete custom, revert to auto
- Source badge: "Auto-generated" or "Custom" on cover
- Vault toggle: lock/unlock icon button → toggleVault + invalidate providers
- Chapter list: tap → navigate to reader page

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
- **Render Scale**: radio 150% (Cepat) / 200% (Tajam)
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
scanNotifierProvider → LibraryScanner.scanFolder(folderPath)
chaptersBySeriesProvider → ChaptersRepository.getChaptersBySeriesId(id)
thumbnailBySeriesProvider → ThumbnailService.getThumbnail(id, path)
```

### Database Migrations (`app_database.dart`)
- v1: initial schema
- v2-6: incremental changes
- v7: `ALTER TABLE series ADD COLUMN is_vaulted INTEGER DEFAULT 0`
  - Wrapped in try-catch for duplicate column safety

### Series Entity
```dart
class Series {
  final int id;
  final String name;
  final String path;
  final bool isVaulted;
  // ... copyWith, toMap, fromMap
}
```
