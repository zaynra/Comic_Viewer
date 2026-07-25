---
name: Lumina Reader
colors:
  surface: '#0b1326'
  surface-dim: '#0b1326'
  surface-bright: '#31394d'
  surface-container-lowest: '#060e20'
  surface-container-low: '#131b2e'
  surface-container: '#171f33'
  surface-container-high: '#222a3d'
  surface-container-highest: '#2d3449'
  on-surface: '#dae2fd'
  on-surface-variant: '#c7c4d7'
  inverse-surface: '#dae2fd'
  inverse-on-surface: '#283044'
  outline: '#908fa0'
  outline-variant: '#464554'
  surface-tint: '#c0c1ff'
  primary: '#c0c1ff'
  on-primary: '#1000a9'
  primary-container: '#8083ff'
  on-primary-container: '#0d0096'
  inverse-primary: '#494bd6'
  secondary: '#b9c8de'
  on-secondary: '#233143'
  secondary-container: '#39485a'
  on-secondary-container: '#a7b6cc'
  tertiary: '#ffb783'
  on-tertiary: '#4f2500'
  tertiary-container: '#d97721'
  on-tertiary-container: '#452000'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#e1e0ff'
  primary-fixed-dim: '#c0c1ff'
  on-primary-fixed: '#07006c'
  on-primary-fixed-variant: '#2f2ebe'
  secondary-fixed: '#d4e4fa'
  secondary-fixed-dim: '#b9c8de'
  on-secondary-fixed: '#0d1c2d'
  on-secondary-fixed-variant: '#39485a'
  tertiary-fixed: '#ffdcc5'
  tertiary-fixed-dim: '#ffb783'
  on-tertiary-fixed: '#301400'
  on-tertiary-fixed-variant: '#703700'
  background: '#0b1326'
  on-background: '#dae2fd'
  surface-variant: '#2d3449'
typography:
  headline-lg:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 34px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
  title-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: Geist
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.05em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 30px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  safe-margin: 20px
  gutter: 12px
---

## Brand & Style

The design system is centered on "Immersive Utility." It prioritizes content above all else, retreating into the background to allow PDFs and comics to take center stage. The brand personality is focused, high-performance, and premium, evoking the feeling of a well-organized digital library.

The style is a hybrid of **Modern Minimalism** and **Glassmorphism**, leveraging the structured hierarchy of Material Design 3 while introducing depth through translucent layers. The goal is to provide a distraction-free environment that feels light and responsive, using subtle motion and depth to guide the user's focus without competing with the visual richness of the reading material.

## Colors

The palette is anchored in a high-contrast dark mode to reduce eye strain during long reading sessions. 

- **Primary:** An Indigo (#6366F1) used sparingly for core actions, progress indicators, and active states.
- **Surface & Background:** The background is a deep charcoal-black (#020617). Interactive surfaces use a semi-transparent slate to facilitate glassmorphism effects.
- **Accents:** A soft blue (#38BDF8) is reserved for sliders, secondary toggles, and "Read" indicators to provide a cool, calm visual cue.
- **Light Mode:** When toggled, the UI flips to a clean white (#FFFFFF) background with light grey (#F1F5F9) surfaces, maintaining the same primary indigo for consistency.

## Typography

This design system utilizes **Inter** for its exceptional legibility and neutral character, ensuring it doesn't distract from the text within documents. 

**Geist** is introduced for labels and technical metadata (page numbers, file sizes, timestamps) to provide a clean, slightly technical aesthetic that feels precise and high-performance.

- **Hierarchy:** Headlines use tight letter spacing and bold weights to feel grounded. 
- **Body Text:** Optimized for UI elements; however, the content (PDF/Comic) remains in its native font.
- **Mobile scaling:** Display titles are reduced on mobile to ensure long book titles do not wrap excessively.

## Layout & Spacing

The layout follows a **Fluid Grid** model with a focus on edge-to-edge content presentation. 

- **Reader View:** A "No Grid" philosophy is applied when a document is open; margins are ignored to allow the content to fill the screen. UI overlays (bars) hover with a 16px inset from the screen edges.
- **Library View:** Uses a 2-column (mobile) or 4-column (tablet) grid for thumbnails.
- **Safe Areas:** Strict adherence to system safe areas (top notch and bottom home indicator) is required. Floating bars should be positioned above the bottom safe area to ensure they appear "detached" from the screen edge.

## Elevation & Depth

This design system uses depth to indicate interactivity and separation from the content.

- **Glassmorphism:** All navigation bars, menus, and bottom sheets use a backdrop blur (20px to 32px) and a subtle 1px inner border (border-white/10 in dark mode) to simulate frosted glass.
- **Z-Axis Hierarchy:**
    1. **Level 0 (Base):** The reading material/document.
    2. **Level 1 (Overlays):** Floating toolbars and top bars.
    3. **Level 2 (Modals):** Bottom sheets and settings panels.
- **Shadows:** Avoid heavy black shadows. Use low-opacity, wide-spread ambient shadows (Indigo-tinted) to lift floating elements off the content layer.

## Shapes

The shape language is defined by **large, friendly radii** that contrast with the often rectangular nature of pages and panels.

- **Floating Bars:** Use `rounded-xl` (1.5rem / 24px) to create a distinct "pill" or "island" look.
- **Thumbnails:** Use `rounded-lg` (1rem / 16px) for comic covers and PDF previews.
- **Buttons/Chips:** Standardized to `rounded-lg` for a soft, tactile feel.
- **Bottom Sheets:** Only the top corners are rounded (24px) to create a "drawer" effect.

## Components

- **Floating Bottom Toolbar:** A pill-shaped bar containing primary navigation (Home, Search, Settings) or reader controls (Brightness, Table of Contents, Page Slider). It should float 16px above the bottom of the screen.
- **Translucent Top App Bar:** A slim bar that appears on tap, displaying the document title and back button. It should use 70% opacity with a heavy backdrop-blur.
- **Smooth Sliders:** Used for page scrubbing and brightness. The track should be thick (8px) and rounded, with the "soft blue" accent for the filled portion.
- **Bottom Sheets:** Triggered for font settings or chapter lists. They should take up no more than 60% of the screen height and feature a subtle drag handle.
- **Thumbnail Grid:** Comic/Book covers should feature a 1px border and a subtle inner glow to make them pop against the dark background.
- **Status Chips:** Small, semi-transparent labels (e.g., "90% Read", "New") placed on the corner of thumbnails using the `label-md` Geist typography.