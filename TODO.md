# TODO — Non-Working Features & Buttons

> Daftar button/feature yang belum di-wire. Belum dikerjakan — hanya dokumentasi.

## 1. Search (Global & Per-Screen)

| Lokasi | Icon | File:Line | Status |
|--------|------|-----------|--------|
| Home page (top bar) | `Icons.search` | `home_page.dart:673` | Empty callback `() {}` |
| Series Detail | `Symbols.search` | `series_detail_page.dart:125` | Empty callback `() {}` |
| History page | `Icons.search_rounded` | `history_page.dart:46-58` | Tidak ada handler sama sekali |

**Infra:** `searchQueryProvider` + `searchResultsProvider` sudah siap di `data_providers.dart` tapi tidak pernah dipanggil dari UI.  
**Perlu:** SearchDelegate, search dialog, atau search bar.

---

## 2. Favorite

| Lokasi | Icon | File:Line | Status |
|--------|------|-----------|--------|
| Series Detail | `Symbols.favorite` (?) | Belum ada di UI | Tidak ada button favorite sama sekali |

**Infra:** `favoriteSeriesProvider`, `isFavoriteProvider`, `FavoritesRepositoryImpl` — semua sudah siap & full CRUD dengan SQLite.  
**Perlu:** Favorite icon di series detail / book card, toggle favorite, favorites tab/list.

---

## 3. Bookmark (Series Detail)

| Lokasi | Icon | File:Line | Status |
|--------|------|-----------|--------|
| Series Detail | `Symbols.bookmark_add` | `series_detail_page.dart:495` | Empty callback `() {}` |

**Infra:** `BookmarkRepositoryImpl` sudah siap. Reader page sudah punya `_checkBookmark()`.  
**Perlu:** Wire button ke bookmark repository.

---

## 4. Overflow / 3-Dot Menu

| Lokasi | Icon | File:Line | Status |
|--------|------|-----------|--------|
| Series Detail | `Symbols.more_vert` | `series_detail_page.dart:512` | Empty callback `() {}` |
| Thumbnail Viewer | `Icons.more_vert_rounded` | `thumbnail_viewer_page.dart:103-116` | Tidak ada handler |

**Perlu:** Bottom sheet / popup menu dengan opsi (edit, delete, vault settings, dll).

---

## 5. Sort Button (Series Detail)

| Lokasi | Icon | File:Line | Status |
|--------|------|-----------|--------|
| Series Detail | `Icons.sort` | `series_detail_page.dart:59` | Empty callback `() {}` |

**Perlu:** Sort options dialog untuk chapters (by number, by date, ascending/descending).

---

## 6. Settings — Static Sections

| Section | File:Line | Masalah |
|---------|-----------|---------|
| **View Mode** | `settings_page.dart:181-243` | Hanya teks "Fit Width" + "Active" — tidak bisa diubah |
| **Scroll Mode** | `settings_page.dart:246-308` | Hanya teks "Vertical Scroll" + "Active" — tidak bisa diubah |

**Perlu:** Hapus atau jadikan kontrol nyata.

---

## 7. Settings — Info Tiles

| Tile | File:Line | Status |
|------|-----------|--------|
| "Version" (0.2.0) | `settings_page.dart:397` | Empty callback `() {}` |
| "Built with" (Flutter + Riverpod) | `settings_page.dart:403` | Empty callback `() {}` |

**Perlu:** Dialog changelog / licenses / tech stack info.

---

## 8. `_ActionButtons` (Dead Widget)

| Lokasi | File:Line | Status |
|--------|-----------|--------|
| Series Detail | `series_detail_page.dart:37, 521-529` | `build()` returns `const SizedBox.shrink()` — tidak render apapun |

**Perlu:** Implementasi (Resume Reading, Mark Read, dll) atau hapus.

---

## 9. Search Icon (History Page — Inert)

| Lokasi | Icon | File:Line | Status |
|--------|------|-----------|--------|
| History page | `Icons.search_rounded` | `history_page.dart:46-58` | Hanya Container + Icon — tidak ada `GestureDetector` atau `onTap` |

**Perlu:** Bungkus dengan `GestureDetector` atau `IconButton`, wire ke search.

---

## 10. Settings Icon (Thumbnail Viewer — Inert)

| Lokasi | Icon | File:Line | Status |
|--------|------|-----------|--------|
| Thumbnail Viewer | `Icons.settings_outlined` | `thumbnail_viewer_page.dart:89-102` | Hanya Container — tidak ada handler |

**Perlu:** Bungkus dengan `GestureDetector`, wire ke settings atau thumbnail preferences.

---

## Total Ringkasan

| Kategori | Jumlah |
|----------|--------|
| Empty callbacks `() {}` | 7 |
| Inert icons (no handler) | 3 |
| Static settings sections | 2 |
| Dead widget (SizedBox.shrink) | 1 |
| **Total non-working** | **13** |
| **Working properly** | ~6 (settings: brightness, night filter, keep screen on, auto continue, direction, orientation) |
