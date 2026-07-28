# AI Execution Guide — Cara Membaca Instruksi User

> Dokumen ini mendokumentasikan pattern komunikasi user dan bagaimana AI harus
> merespon setiap jenis instruksi. Dibuat berdasarkan observasi interaksi langsung.

---

## 1. Nada & Gaya Komunikasi

| Ciri | Contoh | Respon AI |
|------|--------|-----------|
| **Imperatif langsung** | "lakukan", "buat", "cari", "push" | Eksekusi segera tanpa tanya-konfirmasi |
| **Campur bahasa** | "push dlu ke main" / "error masih belum" | Pahami maksud dari konteks, bahasa tidak perlu sempurna |
| **Singkat** | 1-2 kalimat perintah | Jangan minta elaborasi — langsung kerjakan |
| **Feedback failure langsung** | "masih error", "masih tidak" | Artinya fix sebelumnya GAGAL — cari pendekatan baru |
| **Tidak suka analisis panjang** | Tidak minta penjelasan kecuali ditanya | Jawab singkat, langsung ke solusi |

---

## 2. Prioritas Instruksi

### P1 — Push ke Main (Tertinggi)
```
"push dlu ke main"
"push sekarang"
```
**Reaksi:** Segera `git add -A && git commit -m "..." && git push origin main`
- Jangan tunda, jangan tanya, jangan tambah fix lain
- Push dulu, baru lanjut kerja
- Commit message: `"Scope: description"` — bahasa Inggris

### P2 — Fix Bug
```
"masih error", "cari apa masalahnya", "selesaikan"
```
**Reaksi:**
1. Bandingkan dengan branch `backup` jika relevan (`git diff backup..main -- file`)
2. Cari root cause — janga fix gejalanya
3. Jika fix pertama gagal, ganti strategi jangan ulang hal yang sama
4. Setelah fix: `flutter analyze`, build, install ke emulator
5. Push ke main setelah user konfirmasi

### P3 — Dokumen / MD Files
```
"buat md", "tulis di screen spec", "update todo"
```
**Reaksi:**
- Update SCREEN_SPEC.md dengan bug history dan root cause — agar tidak terulang
- Update TODO.md dengan task yang masih pending
- Update PROGRESS.md dengan phase baru
- Update AGENTS.md dengan DO/DON'T rules baru
- Push ke main

### P4 — Build
```
"buat release", "build apk"
```
**Reaksi:**
`flutter build apk --release`
Laporkan path file + ukuran APK

---

## 3. Pola Investigasi Bug

Saat user melaporkan error, ikuti urutan ini:

### Langkah 1 — Compare dengan Backup
```bash
git diff backup..main -- lib/.../file.dart
```
Cari apa yang BERBEDA — asumsikan backup adalah versi yang WORKING

### Langkah 2 — Trace Flow Lengkap
- Baca file terkait dari awal sampai akhir
- Jangan tebak — trace variabel, query, state changes
- Perhatikan: UNIQUE constraints, foreign keys, cascade delete

### Langkah 3 — Cari Chain Reaction
Satu bug sering disebabkan 2-3 bug berantai:
- Bug A (root cause) → menyebabkan Bug B (tersembunyi) → manifestasi Bug C (yang dilihat user)
- Contoh: `deleteSeries` tidak cascade → `Chapter.==` tidak deteksi perubahan → chapter tidak muncul di UI

### Langkah 4 — Safety Net
Setelah fix root cause, tambah safety net (misal: cleanup orphan di awal scan) untuk jaga-jaga kalau ada bug serupa di masa depan.

---

## 4. Aturan Emulator Testing

| Situasi | Tindakan |
|---------|----------|
| User minta test | Build debug APK, install via adb, run `flutter run -d emulator-5554` |
| User lapor "error di homepage" | Cek provider yang error — `seriesAsync.when(error:)` atau Riverpod AsyncError |
| User lapor "0 pages" | Cek `Chapter.totalPages` — apakah `_getPdfPageCount()` dipanggil? |
| User lapor "tidak nemu file" | Cek DB orphaned chapters, cascade delete, dan `Chapter.==` operator |
| User lapor "kualitas jelek" | Cek render scale default — jangan 100%, harus 150% |

---

## 5. Aturan Commit & Push

### Commit Message Format
```
"Scope: description"
```
Contoh:
- `"Fix: cascade delete chapters on deleteSeries"`
- `"Docs: update SCREEN_SPEC with bug history"`
- `"Feat: add vault flat PDF mode"`

### Kapan Commit
- Setiap selesai satu logical fix/feature
- JANGAN gabung banyak hal dalam satu commit
- JANGAN commit tanpa `flutter analyze` = 0 errors

### Kapan Push
- Saat user bilang "push"
- Setelah user confirm fix berhasil
- Jangan push otomatis — tunggu instruksi

---

## 6. Pola Respons

### Saat User Bilang "Error Masih"
```
❌ "Saya sudah coba fix A, B, C..." (defensive)
✅ Langsung cari root cause baru, bandingkan dengan backup, trace flow
```

### Saat User Bilang "Push Dulu"
```
❌ "Sebentar, saya tambah fix lain juga" (menunda)
✅ Push segera, lalu lanjut kerja
```

### Saat User Minta Penjelasan
```
❌ "Berdasarkan analisis saya..." (terlalu panjang)
✅ 2-3 kalimat, langsung ke inti: akar masalah + fix
```

### Saat User Laporkan Bug Baru
```
✅ "Akar masalah: [1 kalimat]. Fix: [file:line] yang diubah"
```

---

## 7. File yang WAJIB Diupdate Saat Fix Bug

Setiap selesai fix bug:

| File | Apa yang ditulis |
|------|------------------|
| `SCREEN_SPEC.md` | Root cause chain, fix, safety net — di `CRITICAL BUG HISTORY` section |
| `AGENTS.md` | Tambah ❌ DON'T dan ✅ DO rules baru |
| `TODO.md` | Update status task |
| `PROGRESS.md` | Tambah ke phase yang sesuai dengan detail bug |

---

## 8. Database Rules (JANGAN Dilanggar)

| Rule | Alasan |
|------|--------|
| `series.path` UNIQUE | Jangan insert duplicate |
| `chapters.file_path` UNIQUE | Jangan insert duplicate |
| Foreign key tidak di-enforce | Manual cascade WAJIB |
| `deleteSeries()` harus hapus chapters dulu | Mencegah orphaned chapters |
| `Chapter.==` harus include `seriesId` | Agar dirty check di scanner bekerja |
| `_getPdfPageCount()` jangan dihapus | totalPages akan selalu 0 |
| Render scale default index 1 (150%) | Kualitas render |

---

## 9. Ringkasan — Alur Kerja Standar

```
User memberi instruksi
  ↓
P1: "push"? → push sekarang, selesai
  ↓
P2: "fix"? 
  → git diff dengan backup
  → trace flow lengkap
  → cari chain reaction (3 bugs berantai)
  → fix root cause + safety net
  → flutter analyze, build, install
  → update semua MD files
  → tunggu instruksi push
  ↓
P3: "build"? → flutter build apk --release
  ↓
P4: "docs"? → update MD files
```
