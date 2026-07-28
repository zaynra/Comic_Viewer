# TODO — Non-Working Features & Buttons

> Daftar button/feature yang belum di-wire. Belum dikerjakan — hanya dokumentasi.

## 1. Search (Global & Per-Screen)

| Lokasi | Icon | File:Line | Status |
|--------|------|-----------|--------|
| Home page (top bar) | `Icons.search` | `home_page.dart` | ✅ Dialog search terhubung ke `searchQueryProvider` |
| Series Detail | `Symbols.search` | `series_detail_page.dart:125` | ✅ Dialog search via home page |
| History page | `Icons.search_rounded` | `history_page.dart:46-58` | ✅ GestureDetector + dialog search |

**Perbaikan:** Search dialog di-homepage & history dengan `searchQueryProvider`.

---

## 2. Favorite

| Lokasi | Icon | File:Line | Status |
|--------|------|-----------|--------|
| Series Detail | `Icons.favorite` / `Icons.favorite_border` | `series_detail_page.dart` | ✅ Favorite toggle button wired |
| Home page | Favorites tab (index 2) | `home_page.dart` | ✅ Tab Favorites + `_buildFavoritesSliver` + `favoriteSeriesProvider` |

**Perbaikan:** Favorite toggle di Series Detail + Favorites tab di Home.

---

## 3. Bookmark (Series Detail)

| Lokasi | Icon | File:Line | Status |
|--------|------|-----------|--------|
| Series Detail | `Symbols.bookmark_add` | `series_detail_page.dart` | ✅ Dialog bookmark + `addBookmark()` call |

**Perbaikan:** Wire button ke `bookmarkRepositoryProvider`.

---

## 4. Overflow / 3-Dot Menu

| Lokasi | Icon | File:Line | Status |
|--------|------|-----------|--------|
| Series Detail | `Symbols.more_vert` | `series_detail_page.dart` | ✅ Bottom sheet dengan opsi (Vault, Edit Cover, Hapus) |
| Thumbnail Viewer | `Icons.more_vert_rounded` | `thumbnail_viewer_page.dart` | ✅ GestureDetector + bottom sheet opsi |

**Perbaikan:** Kedua button di-wire ke bottom sheet.

---

## 5. Sort Button (Series Detail)

| Lokasi | Icon | File:Line | Status |
|--------|------|-----------|--------|
| Series Detail | `Icons.sort` | `series_detail_page.dart:59` | ✅ Bottom sheet sort options (ASC/DESC) |

**Perbaikan:** Dialog dengan opsi Nomor ASC / DESC.

---

## 6. Settings — Static Sections

| Section | File:Line | Status |
|---------|-----------|--------|
| **View Mode** | `settings_page.dart` | ✅ GestureDetector + bottom sheet dengan pilihan `FitMode` |
| **Scroll Mode** | `settings_page.dart` | ✅ GestureDetector + bottom sheet dengan pilihan `ReadingMode` |

**Perbaikan:** Kedua section jadi interaktif dengan bottom sheet dialog + wiring ke `settingsProvider`.

---

## 7. Settings — Info Tiles

| Tile | File:Line | Status |
|------|-----------|--------|
| "Version" (0.2.0) | `settings_page.dart` | ✅ Dialog info versi |
| "Built with" (Flutter + Riverpod) | `settings_page.dart` | ✅ Dialog tech stack |

**Perbaikan:** Kedua tile di-wire ke AlertDialog.

---

## 8. `_ActionButtons` (Dead Widget)

| Lokasi | File:Line | Status |
|--------|-----------|--------|
| Series Detail | `series_detail_page.dart` | ✅ Implementasi: "Lanjutkan Membaca" + "Baca dari Awal" |

**Perbaikan:** Implementasi dengan tombol Resume + Read from Beginning.

---

## 9. Search Icon (History Page — Inert)

| Lokasi | Icon | File:Line | Status |
|--------|------|-----------|--------|
| History page | `Icons.search_rounded` | `history_page.dart` | ✅ GestureDetector + search dialog + `searchQueryProvider` |

**Perbaikan:** Bungkus dengan `GestureDetector`, wire ke search dialog.

---

## 10. Settings Icon (Thumbnail Viewer — Inert)

| Lokasi | Icon | File:Line | Status |
|--------|------|-----------|--------|
| Thumbnail Viewer | `Icons.settings_outlined` | `thumbnail_viewer_page.dart` | ✅ GestureDetector + bottom sheet (Regenerate Thumbnails) |
| Thumbnail Viewer | `Icons.more_vert_rounded` | `thumbnail_viewer_page.dart` | ✅ GestureDetector + bottom sheet (Detail File) |

**Perbaikan:** Kedua icon di-wire dengan `GestureDetector` ke bottom sheet.

---

## 11. Vault — Flat PDF Mode

**Status: ✅ SELESAI**

> Vault scan folder langsung untuk `*.pdf`, setiap PDF = 1 shelf item, tap → reader langsung. Tidak pakai Series/Chapter model.

| # | Todo | Detail |
|---|------|--------|
| 1 | Simpan vault folder path ke SharedPreferences | Key `vault_folder_path`, load otomatis saat start |
| 2 | `_pickVaultFolder()` — ganti logika | Hapus `scanFolder()` + `toggleVault()`. Simpan path, scan recursive `*.pdf`, simpan daftar |
| 3 | `_buildVaultSliver()` — ganti tampilan | Dari `vaultedSeriesProvider` → grid dari `_vaultFiles` state, setiap PDF = 1 item |
| 4 | Tampilkan PDF sebagai shelf item | Setiap PDF tampil sebagai kartu dengan nama file, icon/pdf thumbnail |
| 5 | Tap vault item → Reader | Buat Chapter sementara (id:0, seriesId:0) dari file path → navigasi reader |
| 6 | Load vault folder otomatis | Baca SharedPreferences di initState, scan ulang PDFs tiap vault tab dibuka |
| 7 | Seri detail vault toggle tetap jalan | `isVaulted` di Series Detail tetap bisa toggle, tapi vault tab independen |

---

## Total Ringkasan

| Kategori | Jumlah | Status |
|----------|--------|--------|
| Search (3 lokasi) | 3 | ✅ Selesai |
| Favorite toggle + tab | 2 | ✅ Selesai |
| Bookmark | 1 | ✅ Selesai |
| Overflow menu (2 lokasi) | 2 | ✅ Selesai |
| Sort button | 1 | ✅ Selesai |
| Settings View Mode | 1 | ✅ Selesai |
| Settings Scroll Mode | 1 | ✅ Selesai |
| Settings Info Tiles | 2 | ✅ Selesai |
| `_ActionButtons` dead widget | 1 | ✅ Selesai |
| History search icon | 1 | ✅ Selesai |
| Thumbnail viewer icons | 2 | ✅ Selesai |
| Vault — Flat PDF Mode | 7 | ✅ Selesai |
| **Total** | **20** | **✅ Semua selesai** |
