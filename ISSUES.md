# Omnivious Reader — Issue Log

## Issue #1: Scanner Shows 0 Series Despite Files Present
**Status:** OPEN
**Date:** 2026-07-24
**Severity:** Critical

**Description:**
App shows "Comics" folder with "0 series, 0 chapter" even though test files exist at `/sdcard/Comics/`. The manual path input works (shows "Comics") but scanner finds nothing.

**Evidence:**
- `adb shell ls -laR /sdcard/Comics/` confirms files exist (Sample + Manga folders, 10 PDFs)
- App header shows: "Comics — 0 series, 0 chapter"
- "Tidak ada series ditemukan — Pastikan folder berisi file PDF"

**Root Cause:**
Android 11+ (API 30+) **Scoped Storage** blocks `dart:io` `Directory('/sdcard/Comics').listSync()` from accessing files on external storage, even with `MANAGE_EXTERNAL_STORAGE` permission in manifest.

**Attempted Fixes:**
1. Added `MANAGE_EXTERNAL_STORAGE` permission to `AndroidManifest.xml`
2. Added `requestLegacyExternalStorage="true"` to `<application>` tag
3. Added `Permission.manageExternalStorage.request()` in `setFolderPath()`

**Log Shows:**
```
D/permissions_handler( 5370): No permissions found in manifest for: []22
```
This means `permission_handler` package doesn't recognize the permission format.

**Next Steps:**
- Test on real device (Scoped Storage may behave differently on physical Android)
- Consider using SAF with `OPEN_DOCUMENT_TREE` intent instead of file paths
- Or copy files to app's internal storage

---

## Issue #2: permissions_handler Not Recognizing Permission
**Status:** OPEN
**Date:** 2026-07-24
**Severity:** High

**Description:**
`permission_handler` package logs: `No permissions found in manifest for: []22`

**Root Cause:**
The `permission_handler` package may require permissions to be declared in a specific format or doesn't support `MANAGE_EXTERNAL_STORAGE` on API 33+.

**Fix Needed:**
Check `permission_handler` documentation for correct manifest format or use `open_app_settings()` as fallback.

---

## Issue #3: Emulator Name Shows "gphone" Instead of "Pixel 4"
**Status:** NOT A BUG
**Date:** 2026-07-24
**Severity:** None (Informational)

**Description:**
`flutter run` shows `sdk gphone64 x86 64` — this is the **system image type**, not the AVD name. AVD is still Pixel 4. Expected Flutter behavior.

---

## Issue #4: SAF Blocks Folder Access on Android 11+
**Status:** FIXED
**Date:** 2026-07-24
**Severity:** High

**Description:**
SAF blocks access to `/sdcard/Download/` and root `/sdcard/` with error: "Can't use this folder — To protect your privacy, choose another folder"

**Fix Applied:**
- Added "Masukkan Path Manual" button
- Dialog for direct path entry

---

## Issue #5: Slow First Launch (Skipped Frames)
**Status:** OPEN
**Date:** 2026-07-24
**Severity:** Low

**Description:**
Cold start in debug mode skips 100-165 frames (~2 seconds). Normal for debug builds on emulator.

---

## Issue #6: EGL Warnings
**Status:** OPEN (Cosmetic)
**Severity:** None

**Description:**
Multiple `E/libEGL: called unimplemented OpenGL ES API` in emulator. Normal behavior, no functional impact.

---

## Test Results Summary

| Test | Result | Notes |
|------|--------|-------|
| `adb push` files to emulator | ✅ Files present | `ls -laR` confirms |
| Manual path input | ✅ Works | Shows "Comics" folder |
| Scanner finds PDFs | ❌ 0 series | `dart:io` blocked by Scoped Storage |
| `MANAGE_EXTERNAL_STORAGE` | ❌ Not working | `permission_handler` can't find it |
| SAF folder picker | ⚠️ Partial | Works for some folders, blocked for others |

---

## How to Test

### Push Files:
```bash
adb push test_comics/Sample /sdcard/Comics/
adb push test_comics/Manga /sdcard/Comics/
```

### Run App:
```bash
flutter run
```

### In App:
1. Tap "Masukkan Path Manual" → Enter `/sdcard/Comics` → Tap "Buka"
2. OR Tap 3-dot menu → "Ganti Folder" → Enter path

---

## Test Files

```
/sdcard/Comics/
├── Sample/
│   ├── Chapter_0001.pdf (13KB)
│   ├── Chapter_0002.pdf (13KB)
│   ├── Chapter_0001.json
│   └── metadata.json
└── Manga/
    ├── Chapter_0001.pdf – Chapter_0005.pdf (13KB each)
    └── metadata.json
```
