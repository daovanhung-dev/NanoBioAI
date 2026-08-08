# Coding Implementation Status - Stitch Green Wellness

## Snapshot

- Date: 2026-08-08.
- Scope of this status: canonical Green UI docs, semantic foundation migration, route/surface registry and QA gates.
- Stitch reference inventory: 76 pairs.
- Repository screen/surface specs: 80.
- Current direct routes: V1 27, V2 13, V3 3, Admin 12.
- Admin remains on its independent workspace theme.
- This file does not mark 76/76 visual acceptance or approve any DD.

## Current status

| Wave | Status | Evidence / remaining gate |
| --- | --- | --- |
| 0. Baseline and documentation | In progress | Canonical Green authority and route/surface counts refreshed; full owner/acceptance evidence remains open |
| 1. Foundation, assets and shell | In progress | Semantic Green token work and controlled asset manifest are being integrated; dark/contrast/license evidence remains open |
| 2. Existing Stitch-referenced UI | Not certified | No 76/76 light/dark/adaptive golden evidence is recorded here |
| 3. Guest/Free wellness | Partial | Existing wellness pages and the runtime-only Nami Care hub are routed; `/health-tracking` remains an alias |
| 4. M20-M29, OCR and health hubs | Blocked by approval gates | DD, clinical/privacy and platform contracts are not Approved for business implementation |
| 5. AI, FamilyPlus chat and Sale expansion | Blocked by approval gates | Backend safety, cryptography, retention and trusted RPC contracts require Approved DD/review |
| 6. Cutover | Not started | Requires all 76 reference records and release gates; keep rollback flag for one release |

## Implemented foundation evidence inherited from the prior UI baseline

- Shared motion/feedback/preferences and medical primitives exist.
- Existing consumer, Sale and Admin flows already use common theme APIs to varying degrees.
- Business logic, SQLite, Supabase schema/RLS/RPC and access contracts are outside a visual migration unless separately approved.

This inherited baseline is not proof that a surface matches Stitch Green Wellness.

## Route delta reflected by this status

- `/today-tasks` is active and reads real Lifestyle Schedule state.
- `/water-tracking`, `/weekly-summary`, `/personal-goals`, `/quick-care` and `/gentle-care` expose existing pages.
- `/nami-care` is a concrete hub for existing local wellness pages only; no expert or booking capability is implied.
- `/v3/familyplus` exposes the existing auth/effective-access protected FamilyPlus page; this does not imply chat.

## Certification still required

- Per-reference classification and evidence for all 76 Stitch pairs.
- Roboto bundle verification and deterministic light/dark goldens.
- Contrast, text scale, focus, keyboard, reduced motion and adaptive viewport checks.
- Targeted and full Flutter analyze/test evidence, architecture tests and debug APK.
- Supabase/RLS/device checks where trusted behavior is affected.
- Asset license review and any required clinical/privacy/store/escrow approvals.

Do not represent this migration as production-ready until the applicable gates above are recorded as PASS.
