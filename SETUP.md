# Setup Phase 0 — Comic Viewer

Isi zip ini **bukan** project Flutter lengkap (gradle wrapper, AndroidManifest, dsb tidak ikut serta —
itu harus digenerate oleh `flutter create` di mesin kamu sendiri, karena file-file itu spesifik ke versi
Flutter SDK yang terinstall). Yang ada di sini: semua kode Dart (`lib/`) dan `pubspec.yaml` Phase 0.

## 1. Generate skeleton project

Buka PowerShell di `D:\Zayn\`, lalu:

```powershell
cd D:\Zayn
flutter create --org com.zayn comic_viewer
```

Ini bikin folder lengkap `D:\Zayn\comic_viewer\` (android/, ios/, lib/, pubspec.yaml, dst).

> Nama project **harus** `comic_viewer` (lowercase + underscore) — itu aturan Dart package
> naming, bukan pilihan gaya. Kalau mau nama tampilan beda (mis. "Comic Viewer" atau nama lain),
> itu diatur lewat `android:label` di AndroidManifest, bukan nama folder/package.

## 2. Timpa file yang sudah digenerate

Dari isi zip ini, **replace**:
- `pubspec.yaml` → timpa yang digenerate `flutter create` dengan punya zip ini
- folder `lib/` → hapus isi `lib/main.dart` bawaan, copy semua isi `lib/` dari zip ini ke `D:\Zayn\comic_viewer\lib\`

## 3. Tambah permission di AndroidManifest

Buka `android/app/src/main/AndroidManifest.xml`, tambahkan di dalam tag `<manifest>` (sebelum `<application>`):

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="28" />
```

(Hanya perlu untuk Android 9 lama — Android 10+ pakai SAF lewat `file_picker`, tidak butuh permission ini.)

## 4. Install dependencies & jalankan

```powershell
cd D:\Zayn\comic_viewer
flutter pub get
flutter run
```

## Selesai kalau (checklist Phase 0)
- [ ] App buka tanpa error, tema dark sesuai token (background hampir hitam, aksen lavender)
- [ ] Tombol "Pilih Folder Komik" muncul, tap → folder picker Android kebuka
- [ ] Setelah pilih folder, path-nya tampil di layar dan tetap muncul walau app di-restart (tersimpan lewat SharedPreferences)
- [ ] Tombol berubah jadi "Ganti Folder" setelah ada folder tersimpan

## Kalau ada error saat `flutter pub get`
Kirim full error message-nya ke saya — jangan diutak-atik sendiri dulu, karena kemungkinan cuma soal versi package yang perlu disesuaikan ke Flutter SDK versi kamu.
