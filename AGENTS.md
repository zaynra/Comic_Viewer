# AGENTS.md — Omnivious Reader AI Rules

## Project Identity
- **Nama:** Omnivious Reader
- **Stack:** Flutter stable · Dart 3 · Riverpod · GoRouter · pdfx · sqflite · SharedPreferences
- **Target:** Android (primary), iOS/Windows/Linux (secondary)
- **UI Language:** Bahasa Indonesia
- **Folder:** `D:\zayn\project\comic_viewer\`

## Architecture
### Clean Architecture Layers
```
lib/
├── application/     # Use cases, app-level logic
├── core/            # Constants (AppColors, AppSpacing, AppRadius, AppTextStyles, AppTheme)
├── data/            # Implementations (repositories, providers, database)
│   ├── providers/   # Riverpod providers (data_providers.dart — main barrel)
│   └── repositories/
├── domain/          # Entities, repository interfaces
│   ├── entities/
│   └── repositories/
├── infrastructure/  # Services (pdf_renderer, thumbnail_service, library_scanner, etc.)
├── presentation/    # UI pages & widgets (per feature)
│   ├── home/        # Home page + library grid (shelf layout)
│   ├── reader/      # Reader page (PDF viewer)
│   ├── series_detail/
│   ├── settings/
│   ├── splash/
│   ├── onboarding/
│   ├── history/
│   └── thumbnails/
└── rendering/       # (reserved)
```

### State Management
- **Riverpod** (`flutter_riverpod`) — `ConsumerWidget`, `ConsumerStatefulWidget`, `ref.watch`/`ref.read`
- Providers defined in `lib/data/providers/data_providers.dart` (main barrel)
- Settings: `lib/presentation/settings/providers/settings_provider.dart` — `StateNotifier` + `SharedPreferences` persistence
- All settings changes MUST call `ref.read(settingsProvider.notifier).setXxx()` + SharedPreferences save

## Critical Coding Rules

### DO NOT
- ❌ JANGAN tambah komentar di kode (kecuali TODO/FIXME yang penting)
- ❌ JANGAN buat file baru kalau masih bisa edit existing file
- ❌ JANGAN tambah dependency tanpa izin
- ❌ JANGAN ubah `analysis_options.yaml` tanpa alasan jelas
- ❌ JANGAN gunakan `setState` di Riverpod — pakai `ref.read/write` provider
- ❌ JANGAN hardcode warna/spacing — pakai `AppColors.*`, `AppSpacing.*`, `AppRadius.*`
- ❌ **JANGAN pakai font "Geist"** — tidak tersedia di Google Fonts, selalu fallback ke Inter
- ❌ JANGAN push/commit ke branch `backup` — backup hanya untuk referensi
- ❌ **JANGAN lupa cascade delete chapters saat `deleteSeries`** — lihat Bug #1 di SCREEN_SPEC.md
- ❌ **JANGAN ubah operator `==` Chapter tanpa include `seriesId`** — menyebabkan orphan chapters
- ❌ **JANGAN tambah scale200 ke RenderScale** — hanya 100% dan 150%, dua opsi saja
- ❌ **RenderScale default 100% (index 0)** — jangan ubah ke index 1
- ❌ **JANGAN hapus `_getPdfPageCount()`** — menyebabkan totalPages selalu 0

### DO
- ✅ SELALU jalankan `flutter analyze` setelah selesai coding — pastikan **0 errors**
- ✅ Bahasa Indonesia untuk semua UI text (label, tombol, dialog, snackbar)
- ✅ `const` constructor sebisa mungkin
- ✅ Named parameters untuk widget (kecuali `key` dan `child`)
- ✅ Private fields/methods pakai `_` prefix
- ✅ Ikuti pattern file yang sudah ada (cari referensi dulu sebelum buat baru)
- ✅ `super.key` di constructor parameter
- ✅ Untuk launcher icon: jalankan `dart run flutter_launcher_icons` setelah ubah logo
- ✅ **`deleteSeries()` HARUS cascade**: hapus chapters dulu (`DELETE FROM chapters WHERE series_id = ?`), baru series
- ✅ **Setiap `scanFolder()` panggil `deleteOrphanedChapters()`** sebagai safety net
- ✅ **`_addStandalonePdf` HARUS punya `else` clause** untuk update orphan chapter's seriesId
- ✅ **Hitung `sortOrder` dari `MetadataParser.parseSortOrder()` + existing chapters count**
- ✅ **`totalPages` HARUS dari `_getPdfPageCount()`**, jangan default 0

### Git Workflow
- **Main branch:** `main` — branch utama deployment ke GitHub
- **Backup branch:** `backup` — referensi fitur lama, JANGAN di-touch
- **Development:** langsung di `main` (sudah production)
- SELALU cek `git status` dan `git diff` sebelum commit
- **Commit message format:** `"Scope: description"` e.g. `"Fix: restore _getPdfPageCount for totalPages"`

## Design System & Conventions
- **Theme:** Dark-first, surfaceContainerLowest `#060E20`, primary `#CFBCFF` (lavender)
- **Font:** Inter (via `google_fonts`)
- **Icons:** `material_symbols_icons` (bukan default Material Icons), prefix `Symbols.*`
- **Glassmorphism:** `BackdropFilter` + `ImageFilter.blur` + semi-transparent container
- **Radius tokens:** `AppRadius.sm(4)` / `md(8)` / `lg(12)` / `xl(16)` / `2xl(24)` / `pill(9999)`
- **Spacing tokens:** `AppSpacing.xs(4)` / `sm(8)` / `md(16)` / `lg(24)` / `xl(32)`
- **Button patterns:** `PrimaryButton` (shared widget) untuk CTA, circular `Container + IconButton` untuk sekunder
- **⚠️ JANGAN gunakan icon di `PrimaryButton` dalam Row sempit** — bisa overflow 43px
- **Widget barrel:** `lib/presentation/shared/widgets/widgets.dart` — export semua shared widgets
- **Launcher Icon:** OR logo (assets/images/or_logo.png), adaptive icon dark bg #060E20

## Current Development Phase: Phase 12 — Critical Bug Fixes ✅

### Completed (Phase 11 — Vault + TODO Items)
- [x] Vault Flat PDF Mode + all 20 TODO items (Search, Favorite, Bookmark, Overflow, Sort, Settings, dll)
- [x] Multi-resolution PDF renderer (3-tier cache + progressive loading)
- [x] Shelf layout, glassmorphism, OR logo, launcher icon

### Completed (Phase 12 — Bug Fixes)
- [x] **Bug #1 — Folder import tidak deteksi PDF setelah "Hapus Series"**
  - Fix: `deleteSeries()` cascade hapus chapters, `Chapter.==` include `seriesId`, `_addStandalonePdf` else clause, `deleteOrphanedChapters()` safety net
- [x] **Bug #2 — Overflow 43px "Lanjutkan Membaca"**
  - Fix: Hapus icon, text pendek "Lanjut Baca"
- [x] **Bug #3 — Kualitas PDF jelek**
  - Fix: Render scale default kembali ke 150% (index 1)
- [x] **Bug #4 — Total Pages selalu 0**
  - Fix: Restore `_getPdfPageCount()` method
- [x] **Bug #5 — Nomor chapter selalu #1**
  - Fix: `_addStandalonePdf` hitung `sortOrder` dari `parseSortOrder()` + existing count
- [x] `flutter analyze` = 0 errors

### Pending
- [ ] Performance benchmarks: cold start <200ms, scroll 60fps, RAM <150MB
- [ ] Build APK release verification
- [ ] Background isolate rendering fix (`BackgroundIsolateBinaryMessenger` error)
- [ ] Scanner speed optimization for large folders

## Key Files Reference
| File | Purpose |
|------|---------|
| `lib/presentation/home/pages/home_page.dart` | Home page: shelf layout, vault, tabs, glass top bar |
| `lib/presentation/reader/pages/reader_page.dart` | Progressive loading reader + bottom menu bar + settings sheet |
| `lib/presentation/settings/providers/settings_provider.dart` | All app settings + persistence (⚠️ renderScale default index 1=150%) |
| `lib/infrastructure/services/pdf_renderer.dart` | 3-tier multi-resolution PDF renderer |
| `lib/infrastructure/services/thumbnail_service.dart` | Thumbnail generate/regenerate/custom cover |
| `lib/presentation/series_detail/pages/series_detail_page.dart` | Series detail: thumbnail mgmt, vault toggle, chapters |
| `lib/presentation/settings/pages/settings_page.dart` | Settings page |
| `lib/data/providers/data_providers.dart` | All Riverpod providers barrel |
| `lib/presentation/history/pages/history_page.dart` | History page with grouped history |
| `lib/presentation/splash/pages/splash_page.dart` | Splash with OR logo + TickerProviderStateMixin |
| `lib/data/databases/app_database.dart` | SQLite migrations (v7: is_vaulted) |
| `lib/domain/entities/series.dart` | Series entity with isVaulted field |
| `lib/domain/entities/chapter.dart` | ⚠️ Chapter entity — `==` MUST include `seriesId` |
| `lib/data/repositories/series_repository_impl.dart` | ⚠️ `deleteSeries()` HARUS cascade hapus chapters dulu |
| `lib/infrastructure/services/library_scanner.dart` | ⚠️ Scanner — `_addStandalonePdf` HARUS update orphan chapters |
| `lib/core/constants/app_colors.dart` | Color tokens (MD3 + glassmorphism) |
| `lib/core/constants/app_spacing.dart` | Spacing tokens |
| `lib/core/constants/app_radius.dart` | Radius tokens |
| `lib/core/theme/app_theme.dart` | ThemeData configuration |
| `lib/presentation/shared/widgets/glass_bottom_nav.dart` | Floating pill bottom nav with glassmorphism |
| `SCREEN_SPEC.md` | Detailed screen layout, behavior specs, AND bug history |

## File Change Pattern
```dart
// Imports: dart/flutter → packages → project (urut, group)
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/series.dart';
import '../../reader/providers/reader_provider.dart';
```
