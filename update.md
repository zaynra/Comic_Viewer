# Update Plan: Splash Screen + Figma Mockup Implementation

## Status: PLANNED
## Date: 2026-07-25

---

## Mockup Analysis: Reader Page (PDF Reader)

### Color Palette (Design Tokens)

| Token | Hex | Keterangan |
|---|---|---|
| `background` | `#0B1326` | Deep navy — background utama |
| `surface` | `#0B1326` | Same as background |
| `surface-dim` | `#0B1326` | Dimmed surface |
| `surface-container-lowest` | `#060E20` | Ter gelap |
| `surface-container-low` | `#131B2E` | Sangat gelap |
| `surface-container` | `#171F33` | Gelap |
| `surface-container-high` | `#222A3D` | Medium gelap |
| `surface-container-highest` | `#2D3449` | Paling terang di container |
| `surface-bright` | `#31394D` | Bright surface |
| `primary` | `#C0C1FF` | Lavender blue — aksen utama |
| `primary-container` | `#8083FF` | Primary lebih gelap |
| `on-primary` | `#1000A9` | Text di atas primary |
| `on-surface` | `#DAE2FD` | Text utama (putih kebiruan) |
| `on-surface-variant` | `#C7C4D7` | Text sekunder |
| `secondary` | `#B9C8DE` | Secondary text |
| `secondary-container` | `#39485A` | Container secondary |
| `tertiary` | `#FFB783` | Orange accent |
| `tertiary-container` | `#D97721` | Orange lebih gelap |
| `error` | `#FFB4AB` | Error red |
| `outline` | `#908FA0` | Border/outline |
| `outline-variant` | `#464554` | Border variant |

### Typography

| Style | Size | Line Height | Letter Spacing | Weight | Font |
|---|---|---|---|---|---|
| `headline-lg` | 28px | 34px | -0.02em | 700 | Inter |
| `headline-md` | 22px | 28px | - | 600 | Inter |
| `title-lg` | 18px | 24px | - | 600 | Inter |
| `body-lg` | 16px | 24px | - | 400 | Inter |
| `body-md` | 14px | 20px | - | 400 | Inter |
| `label-md` | 12px | 16px | 0.05em | 500 | Geist |

### Spacing & Radius

| Token | Value |
|---|---|
| `xs` | 4px |
| `sm` | 8px |
| `md` | 16px |
| `lg` | 24px |
| `xl` | 32px |
| `gutter` | 12px |
| `safe-margin` | 20px |
| `radius-lg` | 8px |
| `radius-xl` | 12px |
| `radius-2xl` | 16px |
| `radius-3xl` | 24px |
| `radius-full` | 9999px |

---

### Reader Page Layout

#### 1. Main Canvas (Reading Area)
- Full width, full height, scrollable vertically
- Comic pages: centered, `max-w-4xl` (~896px), `object-contain`
- Page shadow: `shadow-2xl`
- Gap antar halaman: `mt-1` (4px)
- Scrollbar hidden (immersive)

#### 2. Top App Bar
- **Posisi:** Fixed top, full width, z-50
- **Background:** `surface-container-highest/80` + `backdrop-blur-xl`
- **Border:** bottom `white/5`
- **Padding:** `px-md py-sm` (16px horizontal, 8px vertical)
- **Layout:**
  - Kiri: Tombol back (`arrow_back` icon)
  - Tengah: Logo (32x32 rounded) + Title "Omnivious Reader" + Badge counter "15 / 248"
  - Kanan: Tombol search

#### 3. Scrub Slider (Page Navigation)
- **Posisi:** Fixed bottom, z-50
- **Container:** `surface-container-highest/60` + `backdrop-blur-md`
- **Border:** `white/5`, shadow-lg
- **Shape:** Rounded full
- **Max width:** 448px, centered
- **Padding:** `px-lg py-3` (24px horizontal, 12px vertical)
- **Margin bottom:** 24px
- **Layout:**
  - Kiri: Label nomor halaman saat ini
  - Tengah: Progress bar (height 8px, rounded, bg surface-container)
    - Fill: primary color
    - Handle: 16x16 circle, primary, border 2px surface, glow effect
  - Kanan: Label total halaman

#### 4. Bottom Nav Bar
- **Posisi:** Bawah scrub slider
- **Background:** `surface-container-high/90` + `backdrop-blur-2xl`
- **Border:** `white/10`, shadow-2xl
- **Shape:** Rounded full
- **Max width:** 384px, centered
- **Padding:** `px-6 py-3` (24px horizontal, 12px vertical)
- **Gap:** 16px
- **Buttons:**
  - Prev (`skip_previous`)
  - Next (`skip_next`)
  - Settings (`settings`)
  - More (`more_horiz`)
  - Each: p-12, rounded-full, text on-surface-variant
  - Hover: text-primary, bg-white/5, icon scale-110

#### 5. Behavior
- Tap canvas → toggle UI visibility (300ms fade transition)
- UI visible by default
- Hide/show: opacity transition

---

## Perbedaan dengan Implementasi Saat Ini

| Aspek | Mockup | Implementasi Sekarang |
|---|---|---|
| **Warna background** | `#0B1326` (navy) | `#131313` (hitam) |
| **Warna primary** | `#C0C1FF` (lavender) | `#CFBCFF` (hampir sama) |
| **Top bar** | Glassmorphism blur | Gradient hitam |
| **Bottom bar** | Rounded pill nav | Linear gradient + row |
| **Scrub slider** | Floating pill container | Inline slider |
| **Page counter** | Badge di top bar | Label di slider |
| **Nav buttons** | 4 tombol (Prev, Next, Settings, More) | 5 tombol (skip_prev, prev, slider, next, skip_next) |
| **Blur effects** | backdrop-blur-xl/2xl | Tidak ada |
| **Shadow** | shadow-lg/2xl | Tidak ada |
| **Border** | white/5, white/10 | Tidak ada |
| **Icon style** | Material Symbols Outlined | Material Symbols (sama) |
| **Logo di top bar** | Ada (32x32 rounded) | Tidak ada |

---

## Rencana Implementasi

### Phase A: Update Design Tokens
1. Update `app_colors.dart` — mapping warna baru dari mockup
2. Update `app_spacing.dart` — sesuaikan spacing tokens
3. Update `app_radius.dart` — tambah radius tokens
4. Update `app_theme.dart` — gunakan warna baru

### Phase B: Redesign Reader Page
1. Top bar — glassmorphism style, logo, badge counter
2. Scrub slider — floating pill container
3. Bottom nav — rounded pill dengan 4 tombol
4. Tap zones — sesuaikan dengan layout baru
5. Transition animations — fade in/out 300ms

### Phase C: Update Other Pages (menunggu mockup lain)
1. Home page — sesuaikan dengan mockup
2. Series detail — sesuaikan dengan mockup
3. Settings — sesuaikan dengan mockup

---

## Yang Menunggu dari User

| Item | Status |
|---|---|
| Figma link (lainnya) | **MENUNGGU** — halaman home, series detail, settings |
| Splash logo | **MENUNGGU** |
| Konfirmasi warna | Apakah `#0B1326` (navy) atau tetap `#131313` (hitam)? |

---

## Execution Order
1. Tunggu semua mockup dari user
2. Document semua findings di `update.md`
3. Phase A: Update design tokens
4. Phase B: Redesign reader page
5. Phase C: Update other pages
6. Phase D: Splash screen (setelah logo diterima)
