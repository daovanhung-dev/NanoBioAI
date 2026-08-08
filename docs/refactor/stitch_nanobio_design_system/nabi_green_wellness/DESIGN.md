---
name: NaBi Green Wellness
colors:
  surface: '#f5faf7'
  surface-dim: '#d6dbd8'
  surface-bright: '#f5faf7'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f0f5f2'
  surface-container: '#eaefec'
  surface-container-high: '#e4e9e6'
  surface-container-highest: '#dee4e1'
  on-surface: '#171d1b'
  on-surface-variant: '#3d4a42'
  inverse-surface: '#2c3230'
  inverse-on-surface: '#edf2ef'
  outline: '#6d7a71'
  outline-variant: '#bccabf'
  surface-tint: '#006c48'
  primary: '#006a46'
  on-primary: '#ffffff'
  primary-container: '#008559'
  on-primary-container: '#f6fff6'
  inverse-primary: '#62dda3'
  secondary: '#1d6a51'
  on-secondary: '#ffffff'
  secondary-container: '#a4efce'
  on-secondary-container: '#226f55'
  tertiary: '#006a43'
  on-tertiary: '#ffffff'
  tertiary-container: '#008656'
  on-tertiary-container: '#f6fff6'
  error: '#C64A4A'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#7ff9be'
  primary-fixed-dim: '#62dda3'
  on-primary-fixed: '#002113'
  on-primary-fixed-variant: '#005235'
  secondary-fixed: '#a7f2d1'
  secondary-fixed-dim: '#8bd5b6'
  on-secondary-fixed: '#002116'
  on-secondary-fixed-variant: '#00513b'
  tertiary-fixed: '#70fcb7'
  tertiary-fixed-dim: '#50df9c'
  on-tertiary-fixed: '#002112'
  on-tertiary-fixed-variant: '#005233'
  background: '#f5faf7'
  on-background: '#171d1b'
  surface-variant: '#dee4e1'
  primary-soft: '#DDF6E9'
  mint-surface: '#EAF9F1'
  text-primary: '#12352A'
  text-secondary: '#60766E'
  text-muted: '#8A9B94'
  border-soft: '#D9E9E1'
  focus-ring: '#68D9A5'
  energy-yellow: '#FFC857'
  calm-blue: '#58B9E8'
  care-coral: '#FF7D75'
  personal-purple: '#8B7CF6'
  success: '#14885F'
  warning: '#B7791F'
  info: '#247CA8'
typography:
  display-hero:
    fontFamily: Roboto
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 38px
    letterSpacing: -0.6px
  screen-title:
    fontFamily: Roboto
    fontSize: 26px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.4px
  section-title:
    fontFamily: Roboto
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 26px
    letterSpacing: -0.2px
  body-base:
    fontFamily: Roboto
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Roboto
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 21px
  cta:
    fontFamily: Roboto
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.2px
  label-chip:
    fontFamily: Roboto
    fontSize: 13px
    fontWeight: '500'
    lineHeight: 18px
    letterSpacing: 0.1px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  xxs: 2px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  page-padding: 16px
  section-gap: 24px
  card-padding: 16px
---

## Brand & Style

The design system embodies a **"Companion, Not Clinician"** philosophy, moving away from sterile, blue-heavy medical aesthetics toward a warm, restorative, and growth-oriented visual identity. The system is built for the NanoBio ecosystem, prioritizing a Vietnamese-first user experience that is supportive, non-judgmental, and approachable.

### Design Style: Expressive Minimalism
The visual direction combines **Modern Corporate** reliability with **Soft Minimalism** and subtle **Glassmorphism**. 
- **Focus:** One primary focal point per viewport (e.g., a central health score or a Nabi Assistant prompt).
- **Layout:** "Bento-style" modular grouping of biometric data into clean, rounded cards.
- **Tone:** Professional yet warm, using natural greens and organic shapes to signal vitality and daily wellness.
- **Narrative:** The UI acts as a gentle guide. Information is layered gracefully using tonal separation rather than aggressive shadows.

## Colors

The palette is rooted in **NaBi Green Wellness**, transitioning from clinical blues to organic, botanical greens.

- **Primary & Tonal Foundations:** `#14A36F` serves as the core wellness signal for CTAs and active states. Supporting tones like `mint-surface` and `green-soft` create a layered, calm environment.
- **Semantic Accents:** Accents are category-specific: `energy-yellow` for activity, `calm-blue` for sleep/hydration, and `personal-purple` for AI-driven insights.
- **Functional States:** Use `success`, `warning`, and `error` for clear system feedback.
- **Gradients:** 
    - **Primary CTA:** Linear `#0F8E62` → `#32C789` (135deg).
    - **Hero Panels:** Linear `#075E45` → `#14A36F` → `#55DBA1`.
- **Text:** High-contrast `text-primary` (`#12352A`) ensures readability against light green and white surfaces.

## Typography

This design system uses **Roboto** as the primary typeface, optimized for Vietnamese diacritics.

- **Vietnamese Optimization:** Maintain a minimum line height of 1.5x for body text to prevent tone marks from clipping.
- **Case Style:** Preference for **Sentence case** across all labels and titles to maintain a conversational and supportive tone.
- **Hierarchy:** Display styles are reserved for key health metrics and hero titles. Screen titles provide immediate context at the top of views.
- **Scaling:** For mobile devices, `display-hero` should scale down to 28px if necessary to prevent awkward line breaks in longer Vietnamese words.

## Layout & Spacing

The layout follows a **4/8-based rhythm** to ensure mathematical harmony across components.

- **Bento Grid Model:** Content is organized into modular cards. On mobile, this results in a single-column stack. On tablet/desktop, cards reflow into a multi-column grid with a 24px gutter.
- **Page Structure:** Standard mobile pages use 16px horizontal padding. Vertical sections are separated by a 24px gap.
- **Touch Safety:** All interactive elements must maintain a minimum **48dp touch target**.
- **Reflow:** Large hero panels transition from full-width mobile cards to side-by-side bento blocks on larger screens.

## Elevation & Depth

Visual hierarchy is established through **Tonal Layering** and **Soft Shadows**.

- **Surface Tiers:**
  - **Level 0 (Flat):** `page-background` (`#F6FBF8`).
  - **Level 1 (Subtle):** `mint-surface` (`#EAF9F1`) used for secondary containment.
  - **Level 2 (Raised):** `#FFFFFF` surfaces with a 1px `border-soft` and a very soft green-tinted shadow (8% opacity of `#14A36F`).
  - **Level 3 (Hero):** Floating elements and active buttons with a 16% opacity shadow, 20px blur, and 8px vertical offset.
- **Glassmorphism:** Reserved for navigation bars and transient top-level overlays. Use 16px backdrop blur with a semi-transparent white tint.

## Shapes

The shape language is organic and friendly, utilizing high corner radii to avoid "clinical" sharpness.

- **Standard Cards:** 20px radius.
- **Inputs:** 12–14px radius.
- **Bottom Sheets:** 28px top-corner radius to create a soft, protective feel.
- **Interactive Pills:** Full capsule (9999px) for chips, tags, and specific filter actions.
- **Borders:** Default to 1px width. Selected or active states increase to 1.5px using the `primary_color_hex`.

## Components

### Buttons
- **Primary:** Gradient fill (`#0F8E62` to `#32C789`) with white text and a subtle green shadow.
- **Secondary:** `mint-surface` background with a 1px primary border.
- **Destructive:** `care-coral` tint background with `#C64A4A` text.

### Inputs
- **Style:** Floating labels with persistent helper text below.
- **States:** Focus state uses a 1px primary border and a soft green focus ring halo.

### Health Metrics
- **Score Rings:** Circular progress components using the hero gradient. Central value in `display-hero` style.
- **Metric Tiles:** White 20px rounded cards with a leading category icon (e.g., Energy, Sleep) on a pastel background.

### Nabi Assistant
- **Avatar:** The mascot appears in speech bubbles.
- **Speech Bubbles:** 20px rounded containers with a 4px corner adjustment at the point of origin. Background is `mint-surface`.

### Navigation
- **Mobile:** Bottom navigation bar with a 4px green dot indicator for the active state.
- **Adaptive:** Navigation rail for tablet/desktop (72dp width) using rounded soft-green containers for active items.

### System States
- **Loading:** Skeleton shimmer using a pulse between `mint-surface` and white.
- **Empty:** Centered Nabi mascot illustration with a warm Vietnamese prompt and a single CTA.