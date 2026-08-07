# NanoBio Material 3 Expressive Design — Re-execution 2026-08-07

This directory is the canonical UI/UX design handoff generated against `daovanhung-dev/NanoBioAI` commit `d126e8ad0c482e3eacc373f35b37f339dd37a8cb`.

## Design language
**NanoBio Calm Expressive Health** combines Material 3 Expressive hierarchy/shape/motion with calm medical presentation, glanceable information and contextual Nabi behavior.

## Non-negotiable
1. No business logic, persistence, access, quota or trust-boundary change is implied by these docs.
2. Source runtime beats this documentation when drift is detected.
3. Active, source-only, alias and coming-soon surfaces remain explicitly different.
4. Theme tokens/primitives are the implementation path; no page-level parallel style system.
5. Vietnamese copy, accessibility, reduced motion and narrow-screen behavior are required.

## Read pack
1. `00_NABI_KINETIC_AURA_MASTER_DESIGN.md`
2. `03_MOTION_SYSTEM.md`
3. `05_SOUND_HAPTIC_SYSTEM.md`
4. `12_UI_FILE_DESIGN_MATRIX.md`
5. One `groups/*.md` file
6. `15_CODING_PLAN.md`
7. Exact `screens/*.md` for touched surface

## Coverage
- Screen/surface specs: **79**
- Active route contracts: V1 20, V2 13, V3 2, Admin 12.
- Additional coverage: onboarding internals, V1 source-only/embedded pages, V3 FamilyPlus source, Sale internal surfaces, Admin shell/gate/dialogs.
