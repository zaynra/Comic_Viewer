# TODO — Future Tasks & Improvements

> Semua item Phase 11 (20 buttons/features) sudah ✅ selesai.
> Berikut adalah task untuk rilis selanjutnya.

## Phase 13 — Performance & Stabilitas

| # | Task | Detail | Status |
|---|------|--------|--------|
| 1 | Performance benchmarks | Cold start <200ms, scroll 60fps, RAM <150MB | ⏳ |
| 2 | Build APK release verification | Build release + test di device fisik | ⏳ |
| 3 | Test scenarios | Fast scroll, chapter change, vault open, settings change | ⏳ |
| 4 | Background isolate rendering | Fix `BackgroundIsolateBinaryMessenger` error saat `compute()` | ⏳ |
| 5 | Scanner speed optimization | Scan folder besar (>100 PDF) tanpa blocking UI terlalu lama | ⏳ |

## Phase 14 — UX Improvements

| # | Task | Detail | Status |
|---|------|--------|--------|
| 1 | Edit Cover | Implementasi upload cover dari galeri + regenerate dari PDF | ⏳ |
| 2 | Bookmark management | Lihat daftar bookmark, hapus bookmark | ⏳ |
| 3 | Search di Series Detail | Search dialog spesifik untuk chapter dalam satu series | ⏳ |
| 4 | Multiple library folders | Support multiple root folders (bukan cuma 1) | ⏳ |
| 5 | Folder view | Tampilan folder tree (bukan cuma shelf) | ⏳ |

## Known Bugs (Belum Diperbaiki)

| # | Bug | Severity | Status |
|---|-----|----------|--------|
| 1 | Background isolate rendering gagal — `BackgroundIsolateBinaryMessenger` tidak tersedia di isolate. Low-res render fallback ke main thread (still works, slower) | Medium | ⏳ |
| 2 | PDF page count via `PdfDocument.openFile` blocking — memperlambat scan untuk folder besar | Low | ⏳ |
