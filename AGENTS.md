# AGENTS.md — Omnivious Reader AI Rules

## Project Identity
- **Nama:** Omnivious Reader
- **Stack:** Flutter stable · Dart 3 · Riverpod · GoRouter · pdfx · sqflite · SharedPreferences
- **Target:** Android (primary), iOS/Windows/Linux (secondary)
- **UI Language:** Bahasa Indonesia
- **Folder:** `D:\zayn\project\comic_viewer_phase0\comic_viewer\`

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
│   ├── home/        # Home page + library grid
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
- ❌ JANGAN commit/ push tanpa diminta
- ❌ JANGAN tambah dependency tanpa izin
- ❌ JANGAN ubah `analysis_options.yaml` tanpa alasan jelas
- ❌ JANGAN gunakan `setState` di Riverpod — pakai `ref.read/write` provider
- ❌ JANGAN hardcode warna/spacing — pakai `AppColors.*`, `AppSpacing.*`, `AppRadius.*`
- ❌ **JANGAN pakai font "Geist"** — tidak tersedia di Google Fonts, selalu fallback ke Inter
- ❌ JANGAN tanya/minta push ke main — kerja di branch `desain`

### DO
- ✅ SELALU jalankan `flutter analyze` setelah selesai coding — pastikan **0 errors**
- ✅ Bahasa Indonesia untuk semua UI text (label, tombol, dialog, snackbar)
- ✅ `const` constructor sebisa mungkin
- ✅ Named parameters untuk widget (kecuali `key` dan `child`)
- ✅ Private fields/methods pakai `_` prefix
- ✅ Ikuti pattern file yang sudah ada (cari referensi dulu sebelum buat baru)
- ✅ `super.key` di constructor parameter

### Git Workflow
- **Main branch:** `main` (stable, jangan commit langsung)
- **Development branch:** `desain` (push di sini)
- **Backup branch:** `backup` (sync dari desain)
- SELALU cek `git status` dan `git diff` sebelum commit

## Design System & Conventions
- **Theme:** Dark-first, surfaceContainerLowest `#060E20`, primary `#CFBCFF` (lavender)
- **Font:** Inter (via `google_fonts`)
- **Icons:** `material_symbols_icons` (bukan default Material Icons), prefix `Symbols.*`
- **Glassmorphism:** `BackdropFilter` + `ImageFilter.blur` + semi-transparent container
- **Radius tokens:** `AppRadius.sm(4)` / `md(8)` / `lg(12)` / `xl(16)` / `2xl(24)` / `pill(9999)`
- **Spacing tokens:** `AppSpacing.xs(4)` / `sm(8)` / `md(16)` / `lg(24)` / `xl(32)`
- **Button patterns:** `PrimaryButton` (shared widget) untuk CTA, circular `Container + IconButton` untuk sekunder
- **Widget barrel:** `lib/presentation/shared/widgets/widgets.dart` — export semua shared widgets

## Current Development Phase: PDF Optimization & Settings Fixes
### Completed (Phase 0-3, 5.1)
- [x] Multi-resolution PDF renderer (3-tier cache: thumbnail 0.5x / lowRes 1.0x / highRes 1.5x-2.0x)
- [x] Background low-res rendering via `compute()` isolate
- [x] Progressive loading (`_ProgressivePageImage`): blurred thumb → low-res → high-res
- [x] Scroll-based prefetch (visible ±2 lowRes, high-res upgrade after 2s idle)
- [x] Render Scale setting: 150% (Cepat) / 200% (Tajam)
- [x] All settings buttons wired to Riverpod notifiers (brightness, night filter, keep screen on, auto continue, direction, orientation)
- [x] View mode / scroll mode simplified to fitWidth + vertical only
- [x] Thumbnail management UI (Series Detail): regenerate, choose custom cover, source badge
- [x] Settings icon in reader top bar → settings sheet
- [x] Controls auto-show/tap-to-toggle in reader
- [x] `flutter analyze` = 0 errors

### Pending (Phase 4)
- [ ] Performance benchmarks: cold start <200ms, scroll 60fps, RAM <150MB
- [ ] Memory monitoring via `dart:developer` `ProcessInfo.currentRss`
- [ ] Test scenarios: fast scroll, chapter change, settings change

## Key Files Reference
| File | Purpose |
|------|---------|
| `lib/presentation/settings/providers/settings_provider.dart` | All app settings + persistence |
| `lib/infrastructure/services/pdf_renderer.dart` | 3-tier multi-resolution PDF renderer |
| `lib/presentation/reader/pages/reader_page.dart` | Progressive loading reader + settings sheet |
| `lib/infrastructure/services/thumbnail_service.dart` | Thumbnail generate/regenerate/custom cover |
| `lib/presentation/series_detail/pages/series_detail_page.dart` | Series detail with thumbnail management |
| `lib/presentation/settings/pages/settings_page.dart` | Settings page (simplified) |
| `lib/data/providers/data_providers.dart` | All Riverpod providers barrel |
| `lib/presentation/home/pages/home_page.dart` | Home page with library grid |
| `lib/core/constants/app_colors.dart` | Color tokens (MD3 + glassmorphism) |
| `lib/core/constants/app_spacing.dart` | Spacing tokens |
| `lib/core/constants/app_radius.dart` | Radius tokens |
| `lib/core/theme/app_theme.dart` | ThemeData configuration |

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
