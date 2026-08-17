# NanoBio Blue Wellness Design - Canonical UI handoff

This directory is the canonical UI/UX handoff for Blue Wellness. The historical Stitch Green references remain layout/composition inputs, while the Blue Wellness tokens in this handoff are the palette authority. The repository inventory baseline remains `daovanhung-dev/NanoBioAI` commit `d126e8ad0c482e3eacc373f35b37f339dd37a8cb`; route and surface classifications were refreshed from the working tree on 2026-08-08.

## Source authority

1. For the 76 Stitch references under `docs/refactor/stitch_nanobio_design_system/`, `screen.png` decides layout and visual composition; `code.html` decides typography and non-color token intent. Blue Wellness decides brand color.
2. Approved DD and current runtime decide behavior, data, access, quota, payment and trust boundaries. Sample HTML links or values never override them.
3. A Stitch asset without verified license is reference/golden-only. Production uses approved local assets, initials, runtime data or a neutral placeholder.
4. Admin has no Stitch reference and keeps its independent workspace theme. It adopts shared Roboto typography, accessibility, focus and dark-mode compatibility only.

## Design language

**NanoBio Blue Wellness** combines calm wellness presentation with Material 3 semantic hierarchy, restrained motion and contextual Nabi Blue support. Blue owns brand/navigation/CTA hierarchy; green remains the health, leaf, success, nutrition and positive-progress accent. Product is NanoBio, companion is Nabi, and the care hub remains Nami Care.

## Non-negotiable

1. No business logic, persistence, access, quota or trust-boundary change is implied by these docs.
2. Runtime and Approved DD beat this documentation when business behavior drifts.
3. Active, alias, placeholder, locked and source-only surfaces remain explicitly different.
4. Theme extensions and semantic primitives are the implementation path; do not create page-level parallel palettes.
5. Vietnamese copy, Roboto, accessibility, reduced motion, safe areas, keyboard behavior and narrow-screen support are required.
6. Do not embed Stitch HTML/WebView/Tailwind, hotlink remote assets or ship sample people, health values, QR, revenue or transactions.
7. `STITCH_GREEN_UI_ENABLED=true` is a compatibility rollback only; the default presentation is Blue Wellness.

## Read pack

1. `00_NABI_KINETIC_AURA_MASTER_DESIGN.md`
2. `03_MOTION_SYSTEM.md`
3. `05_SOUND_HAPTIC_SYSTEM.md`
4. `12_UI_FILE_DESIGN_MATRIX.md`
5. One matching `groups/*.md` file
6. `15_CODING_PLAN.md`
7. The exact `screens/*.md` spec for the touched surface

## Coverage snapshot

- Stitch reference pairs: **76**. This is an input inventory, not a 76/76 acceptance claim.
- Repository screen/surface specs: **80**, including the active `/today-tasks` surface.
- Current direct route contracts: V1 **27**, V2 **13**, V3 **3**, Admin **12**.
- Additional coverage includes onboarding internals, source-only/embedded pages, Sale internals and Admin shell/gate/dialogs.
- Blue visual, dark, accessibility and adaptive QA remain open until evidence is recorded per surface.
