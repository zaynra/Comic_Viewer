# Comic Reader Android — Roadmap (MVP, incremental)

Format tetap PDF. Tiap Phase = milestone yang bisa dijalankan & ditest sendiri sebelum lanjut. Urutan ini sengaja beda dari spec asli (yang menomori fitur, bukan urutan kerja) — di sini diurutkan supaya tiap tahap menghasilkan app yang jalan.

> Mockup yang sudah ada: **Series Detail** saja. Library grid, Reader, dan Settings masih pakai asumsi dari token desain yang sama — begitu mockup-nya menyusul, roadmap ini diupdate lagi biar match persis.

## Perubahan/koreksi dari spec asli
- **Performance target direvisi**: "open PDF 100MB <500ms" tidak realistis untuk decode PDF utuh. Target realistis: *first page visible* <500ms (bukan seluruh file ter-load) — dicapai dengan render on-demand per halaman, bukan load keseluruhan. Target lain (startup <1s, page change <100ms) tetap masuk akal.
- **DI**: skip `get_it`/`injectable`. Riverpod providers saja sudah cukup jadi DI layer — mengurangi boilerplate untuk solo dev.
- **PDF rendering package**: pakai `pdfx` (fork aktif dari `pdf_render`, support page-by-page render + Android native renderer). Alternatif: `syncfusion_flutter_pdfviewer` (lebih matang tapi lebih berat license-wise untuk fitur lanjut — cek dulu kalau butuh fitur premium).
- **File watching**: pakai `watcher` package + periodic diff terhadap SQLite index (bukan full rescan) untuk deteksi new/deleted/renamed.

## Stack final
Flutter (stable) · Dart · Riverpod · `sqflite` (SQLite) · `pdfx` · `path_provider` · `permission_handler` · `watcher` · `google_fonts` (Inter) · Clean Architecture (presentation / application / domain / data / infrastructure / rendering)

## Design system (dari mockup `series_detail.html`)
Semua screen UI (Phase 2, 3, 6, 9) harus konsisten pakai token ini — implementasi sebagai satu `ThemeData`/`ColorScheme` custom di Flutter, bukan di-hardcode per widget.

- **Tema**: dark-first (M3 dark scheme), varian AMOLED = ganti `background`/`surface` ke pure black, varian light disiapkan terpisah nanti
- **Warna inti**: primary `#CFBCFF` (lavender), background `#131313`, surface bertingkat `#1B1B1B → #1F1F1F → #2A2A2A → #353535` (container-low → high), outline `#948E9C`
- **Font**: Inter (via `google_fonts`), scale M3 (display/headline/title/body/label)
- **Icon set**: Material Symbols Outlined (pakai `material_symbols_icons` package, bukan default Material Icons, biar sama persis sama mockup)
- **Radius kustom**: card comic pakai radius 20px (`rounded-comic`), beda dari default M3 radius — jadi custom `BorderRadius` constant, bukan default Card widget
- **Pola komponen yang harus direplikasi**:
  - Hero header: cover art full-bleed + gradient-to-black overlay + judul/author floating di atas gradient
  - Chip badge outline (mis. "Local", genre tags) — border tipis, rounded-xl, teks kecil
  - Chapter row card: surface-container-low, border tipis abu gelap, progress bar 4px di bawah judul chapter (untuk in-progress), strikethrough + check_circle icon (untuk completed)
  - Dua CTA button di header: filled (primary-container) untuk "Continue Reading", outline untuk "Read from Beginning"
  - Favorite button: circular icon button, filled kalau aktif

---

### Phase 0 — Skeleton (0.5–1 hari)
- Init Flutter project, folder structure sesuai Clean Architecture layers
- Setup Riverpod, routing dasar (go_router atau Navigator 2.0 simple)
- Permission handling (storage access, SAF folder picker)
- **Selesai kalau:** app buka, bisa pilih root folder comic via SAF picker

### Phase 1 — Data layer & Library Scanner
- SQLite schema: `Series`, `Chapters`, `LibraryIndex` (tabel lain nyusul di phase berikutnya)
- Recursive scanner: baca folder → deteksi PDF → natural sort (pertahankan konvensi `Chapter_XXXX` 4-digit yang sudah kamu pakai di comic downloader)
- Simpan hasil scan ke SQLite
- **Selesai kalau:** scan folder berisi ratusan PDF, hasil index tersimpan benar & natural-sorted di DB (cek via debug print/table viewer)

### Phase 2 — Library UI + Series Detail
- Grid view: series name, chapter count (cover masih placeholder icon, bukan real thumbnail dulu — thumbnail asli baru Phase 6)
- Setup `ThemeData` custom sesuai Design System di atas (warna, font Inter, radius 20px) — dikerjakan sekali di sini, dipakai semua screen berikutnya
- **Series Detail screen** (sesuai mockup): hero cover + gradient overlay, judul/author, chip badges (Local/genre), tombol Continue Reading + Read from Beginning, list chapter card dengan status (in-progress = progress bar, completed = strikethrough + check_circle)
- Tap series di grid → buka Series Detail
- **Selesai kalau:** grid & Series Detail screen tampil sesuai token desain (warna/radius/font match mockup), data dari Phase 1 muncul benar

### Phase 2b — Reader UI shell & Settings UI shell
- Bikin shell UI kosong (belum ada logic PDF) untuk Reader overlay & Settings, biar Phase 3 & 9 tinggal isi logic, bukan sambil desain
- **Selesai kalau:** ada 2 mockup Flutter screen kosong yang siap diisi

### Phase 3 — Reader core (paling kritis)
- Integrasi `pdfx`, render halaman satu-satu (lazy, async)
- LRU cache 5 halaman (current ± prefetch 2)
- Dispose bitmap saat cache eviction
- Basic gestures: tap kiri/kanan ganti halaman, pinch zoom
- **Selesai kalau:** buka 1 PDF, scroll/tap antar halaman smooth, memory stabil (cek profiler, tidak naik terus saat scroll banyak halaman)

### Phase 4 — Reading progress
- Tabel `Progress`: simpan current page, zoom, reading mode, last opened time per chapter
- Auto-restore saat buka ulang
- "Continue Reading" section di library
- **Selesai kalau:** tutup app di tengah baca, buka lagi → langsung lanjut ke halaman terakhir

### Phase 5 — Chapter navigation
- Deteksi prev/next chapter dari hasil natural sort di Series
- Tombol Previous/Next Chapter di reader, disable kalau tidak ada
- Auto-next (configurable delay) saat halaman terakhir
- Next chapter buka page 1, previous chapter buka last page (configurable)
- **Selesai kalau:** baca sampai halaman terakhir chapter → next chapter otomatis/manual jalan tanpa balik ke library

### Phase 6 — Cover & thumbnail
Prioritas sumber cover per series (cek berurutan):
1. **Cover custom milik user** — kalau ada file gambar (`cover.jpg`/`cover.png`/dll) di folder series, atau user set manual lewat UI (pilih gambar dari galeri/file), pakai itu
2. **Auto-generate dari PDF** — kalau tidak ada cover custom, render halaman pertama chapter pertama (nama series diambil dari nama folder/judul PDF)

Detail kerja:
- Scanner (Phase 1) juga cek file gambar cover di tiap folder series saat scan
- UI: tombol "Ganti Cover" di Series Detail → pilih gambar dari galeri, simpan referensi path-nya (bukan copy file, cukup path)
- Auto-generate tetap jalan di background (isolate) untuk series yang belum punya cover custom, regenerate hanya kalau PDF chapter pertama berubah
- Tabel `Thumbnails`: simpan `source` (`custom` / `generated`) + path, biar tau mana yang boleh di-regenerate otomatis dan mana yang tidak (custom tidak pernah di-overwrite otomatis)
- **Selesai kalau:** series tanpa cover custom nampilin auto-generated thumbnail dari PDF; series dengan cover custom (baik dari folder maupun dipilih manual) selalu pakai itu dan tidak ketimpa auto-generate

### Phase 7 — Search, Favorites, Recent
- Search realtime (series/filename/chapter number)
- Tabel `Favorites`, `Recent`
- **Selesai kalau:** search & favorite/recent berfungsi dan persist

### Phase 8 — Incremental file monitoring
- `watcher` + diff terhadap index → update hanya record yang berubah (new/deleted/renamed/modified)
- **Selesai kalau:** tambah/hapus/rename file di storage, app update index tanpa full rescan manual

### Phase 9 — Settings & polish
- Theme (Light/Dark/AMOLED), reading direction, cache size, keep screen on, restore last page toggle
- Error handling: corrupted PDF, missing file, permission denied, storage removed → pesan user-friendly, tidak crash
- **Selesai kalau:** semua acceptance criteria di spec asli lolos manual test

### Phase 10 (opsional, setelah MVP solid) — Metadata JSON import
- Baca `Chapter_XXXX.json` dari comic downloader kalau ada, fallback parse filename kalau tidak ada
- **Selesai kalau:** import metadata dari file yang dihasilkan comic downloader kamu berhasil terbaca

---

## Belum masuk MVP (sesuai spec, future)
CBZ/CBR support, bookmarks, collections, reading stats, cloud sync, multi-library, plugin system, desktop version.

## Cara pakai roadmap ini
Kerjain satu Phase penuh sampai "Selesai kalau" tercapai sebelum lanjut — tiap Phase independently testable. Kalau mau mulai sekarang, Phase 0 & 1 paling aman buat kickoff karena tidak butuh keputusan besar lagi.
