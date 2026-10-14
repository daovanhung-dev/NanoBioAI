---
name: NanoBio Blue Wellness
colors:
  surface: '#f9f9ff'
  surface-dim: '#cbdbf8'
  surface-bright: '#f9f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f0f3ff'
  surface-container: '#e7eeff'
  surface-container-high: '#dee9ff'
  surface-container-highest: '#d4e3ff'
  on-surface: '#0b1c32'
  on-surface-variant: '#434653'
  inverse-surface: '#213148'
  inverse-on-surface: '#ebf1ff'
  outline: '#737784'
  outline-variant: '#c3c6d5'
  surface-tint: '#2358c1'
  primary: '#0043a7'
  on-primary: '#ffffff'
  primary-container: '#285cc5'
  on-primary-container: '#d4ddff'
  inverse-primary: '#b2c5ff'
  secondary: '#006c49'
  on-secondary: '#ffffff'
  secondary-container: '#91f3c3'
  on-secondary-container: '#00714d'
  tertiary: '#005165'
  on-tertiary: '#ffffff'
  tertiary-container: '#24697f'
  on-tertiary-container: '#a9e6ff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dae2ff'
  primary-fixed-dim: '#b2c5ff'
  on-primary-fixed: '#001847'
  on-primary-fixed-variant: '#0040a0'
  secondary-fixed: '#94f6c6'
  secondary-fixed-dim: '#78d9ab'
  on-secondary-fixed: '#002113'
  on-secondary-fixed-variant: '#005236'
  tertiary-fixed: '#b8eaff'
  tertiary-fixed-dim: '#91cfe8'
  on-tertiary-fixed: '#001f28'
  on-tertiary-fixed-variant: '#004d61'
  background: '#f9f9ff'
  on-background: '#0b1c32'
  surface-variant: '#d4e3ff'
typography:
  headline-lg:
    fontFamily: Roboto Flex
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Roboto Flex
    fontSize: 26px
    fontWeight: '700'
    lineHeight: 34px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Roboto Flex
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 30px
    letterSpacing: '0'
  headline-sm:
    fontFamily: Roboto Flex
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 26px
    letterSpacing: '0'
  body-lg:
    fontFamily: Roboto Flex
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: 0.01em
  body-md:
    fontFamily: Roboto Flex
    fontSize: 15px
    fontWeight: '400'
    lineHeight: 22px
    letterSpacing: 0.01em
  body-sm:
    fontFamily: Roboto Flex
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
    letterSpacing: 0.02em
  label-lg:
    fontFamily: Roboto Flex
    fontSize: 15px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Roboto Flex
    fontSize: 13px
    fontWeight: '500'
    lineHeight: 18px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Roboto Flex
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 14px
    letterSpacing: 0.03em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1.25rem
  space-xs: 0.5rem
  space-sm: 0.75rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

This design system crafts an airy, deeply restorative visual environment for native mobile wellness onboarding in the Vietnamese market. Combining clinical biotechnology precision with serene natural wellness cues, the UI establishes immediate emotional trust, clarity, and gentle momentum. Guided by Nabi, an intelligent companion avatar, the experience should evoke feelings of breathing deeply, morning hydration, clear water, and clinical assurance without ever feeling sterile or intimidating.

The aesthetic philosophy draws on **Airy Modernism with Organic Material 3 behavior**:
- Generous daylight surfaces on cool canvas tones to combat cognitive overload during personal intake.
- Soft organic geometry and droplet/leaf-inspired curves paired with high-contrast typography optimized for tone-marked Vietnamese diacritics.
- Unhurried pacing grounded by solid primary actions, unambiguous navigation anchors, and translucent atmospheric accents.

## Colors

The palette balances technical authority and vitality:
- **Primary Blue (`#285CC5`)**: The core brand anchor. Used for primary interactive triggers, active navigation markers, and focused onboarding states.
- **Deep Blue (`#1C478F`)**: Used for pressed/active button states, deep visual accents, and high-emphasis brand framing.
- **Health Green (`#16845C`)**: Secondary accent embodying bio-vitality, positive health achievements, validation ticks, and wellness milestone tags.
- **Sky (`#9DDCF5`)**: Tertiary tint representing hydration and air; used for subtle graphic badges, inactive step tracks, and soft radial water glows.
- **Mint (`#EAF5EE`)**: Wellness container fill used to house health confirmations, soft badges, and celebratory callouts.
- **Canvas / Background (`#F4F7FB`)**: Cool, desaturated blue-gray ground preventing screen fatigue across extended flows.
- **Surface / Cards (`#FFFFFF`)**: Pure crisp white surfaces elevating active selection states and form structures.
- **Ink / Text Primary (`#14243A`)**: Deep slate-navy text with superior contrast (AA/AAA rated) across all surface backgrounds.
- **Muted / Text Secondary (`#53657B`)**: Supportive neutral for secondary guidance, timestamps, and input hints.

## Typography

Typography prioritizes high-legibility rendering of Vietnamese compound tone marks (`dấu hỏi`, `dấu ngã`, `dấu nặng`, `mũ`, `móc`). Roboto Flex provides robust vertical metric tolerance, preventing diacritic clipping and maintaining strict typographic rhythm.

Key typographic rules:
- **Ascender & Descender Clearance**: Line heights must maintain a minimum 1.4x body ratio and 1.25x headline ratio to avoid tone mark collisions with upper-level underlines or bounding elements.
- **Headlines**: Semi-bold to Bold weights in deep `#14243A` deliver authoritative yet approachable onboarding questions.
- **Body & Prompts**: Set at 15px/16px to ensure effortless reading for varied age brackets on mobile screens.
- **Micro-labels**: Always uppercase or semi-bold when denoting status, step counters, or scientific biomarkers.

## Layout & Spacing

The layout is built upon an 8dp baseline grid (0.5rem increments), ensuring rhythmic cohesion across mobile screen heights and widths.

- **Canvas Safe Boundaries**: Outer margins are locked to 20px (1.25rem) on small phones, scaling to 24px (1.5rem) on tablets.
- **Step Header Architecture**: A reserved top app bar zone (56dp standard height) housing the prominent back button, the 9-step progress tracker, and Nabi guide presence.
- **Bottom Action Dock**: Pinned primary action bar maintaining 48dp minimum height (56dp standard button) with safe-area insets (`env(safe-area-inset-bottom)` + 16px).
- **Vertical Flow Rhythm**: 
  - 8px (`space-xs`) between related input label and container.
  - 16px (`space-md`) vertical separation between stacked selectable cards.
  - 24px (`space-lg`) separation between conversational intro blocks and form modules.
  - 32px (`space-xl`) buffer above bottom-docked navigation buttons.

## Elevation & Depth

Visual hierarchy leverages ambient, tinted daylight shadows paired with subtle border containment. Heavy dark drop shadows are forbidden.

- **Surface Level 0 (Canvas)**: `#F4F7FB` base plane.
- **Surface Level 1 (Default Resting Cards)**: `#FFFFFF` fill with an ultra-soft cool ambient shadow: `box-shadow: 0px 4px 16px rgba(20, 36, 58, 0.04), 0px 1px 3px rgba(20, 36, 58, 0.02)`. Outlined with a hair-thin perimeter `1px solid rgba(40, 92, 197, 0.06)`.
- **Surface Level 2 (Selected / Active Focus Cards)**: Elevated white card with a saturated boundary `1.5px solid #285CC5` and a dynamic soft blue bloom: `box-shadow: 0px 8px 24px rgba(40, 92, 197, 0.12), 0px 2px 6px rgba(40, 92, 197, 0.06)`.
- **Surface Level 3 (Sticky Bottom Bar & Modal Sheets)**: Ambient upward diffuse elevation: `box-shadow: 0px -4px 20px rgba(20, 36, 58, 0.05)`.
- **Decorative Water & Leaf Depth**: Organic background blurs use semi-transparent soft shapes (`#9DDCF5` at 15% opacity, `#EAF5EE` at 40% opacity) positioned behind content cards with `backdrop-filter: blur(20px)` to evoke natural translucency.

## Shapes

The design system employs a soft, human-centric organic curve geometry:
- **Cards and Module Panels**: Standardized between 18px and 22px border radii (`1.25rem` to `1.375rem`), balancing physical comfort with structure.
- **Interactive Buttons**: Standard primary action buttons use full pill shape or strong 16px curves (`rounded-lg`) to encourage tactile interaction.
- **Selection Chips & Step Badges**: 12px to full-capsule pill radius.
- **Input Fields**: 14px to 16px soft cornering to preserve card harmony.
- **Avatar & Icon Badges**: Circular (`50%` or 24px squash) with gentle water-droplet curves where asymmetric organic accents are introduced.

## Components

### 9-Step Onboarding Progress Indicator
- **Geometry**: Segmented top linear bar divided into 9 continuous capsules (height: 4px, margin: 4px).
- **Visual Logic**: Inactive segments render in `#E2E8F0` or `#9DDCF5` (at 40% opacity). Completed segments render in `#16845C` (Health Green). Active segment renders in `#285CC5` (Primary Blue) with an optional subtle pulse or numeric step tag (`Bước 3/9`) positioned cleanly below.

### Navigation Header & Back Button
- **Placement**: Top-left alignment with generous hit boundary (minimum 48dp x 48dp).
- **Styling**: Circular white backing (`#FFFFFF`) with resting Level 1 elevation, housing a prominent left chevron in `#14243A`. 
- **Nabi Guide Anchor**: Top-right compact avatar preview (36dp) accompanied by contextual speech hints when user encounters complex biometric entries.

### Buttons
- **Primary CTA**: Solid `#285CC5`, height 54dp, width 100%, text `#FFFFFF` (Label-lg / 600 weight). Pressed state transitions to Deep Blue `#1C478F`. Minimum touch height: 48dp.
- **Secondary / Ghost**: White background `#FFFFFF`, border `1.5px solid #285CC5`, text `#285CC5`.
- **Health Highlight Action**: Solid `#16845C` with white text for intake completion or habit confirmation moments.

### Single & Multi-Select Cards
- **Dimensions**: Full container width, minimum height 64dp, internal padding `16px 20px`.
- **Default State**: Surface `#FFFFFF`, border `1px solid rgba(40, 92, 197, 0.08)`, Level 1 shadow.
- **Selected State**: Background tint `#F4F7FB`, border `2px solid #285CC5`, icon checkmark filled with `#285CC5`. Contains custom illustrations or icon badges with `#9DDCF5` / `#EAF5EE` dual-tone backgrounds.

### Input Fields
- **Container**: Height 56dp, radius 16px, background `#FFFFFF`, border `1px solid #D6E0EC`.
- **Focus State**: Border `2px solid #285CC5`, subtle halo glow.
- **Labeling**: Floating label or persistent top label in `#53657B` (Body-sm), ensuring Vietnamese accents remain clearly separated from the field baseline.

### Checkboxes & Radio Indicators
- **Radio Dots**: Outer 22dp circle, `2px` stroke in `#285CC5`, inner active pip 12dp solid circle.
- **Checkboxes**: 22dp rounded box (radius 6px), active fill `#16845C` with crisp white checkmark.

### Nabi Companion Message Bubble
- **Container**: Fill `#EAF5EE`, border `1px solid #C6E6D2`, corner radius 18px (with a soft pointed anchor toward the avatar).
- **Text**: `#14243A` with high-emphasis guide phrases in `#16845C`.