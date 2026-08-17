# Coding Plan - Blue Wellness

Each wave requires state parity, visual hierarchy, adaptive layout, motion/feedback, accessibility QA and targeted tests. UI work must not invent business behavior.

## Wave 0 - Baseline and documentation gates

Fix contradictory contracts, refresh the canonical surface/route registry and record owners, states and acceptance evidence. New or changed business modules stay placeholders until the required PO, Tech, QA and Clinical/Privacy approvals are explicitly recorded.

## Wave 1 - Foundation, assets and shell

Introduce context-aware semantic colors, deterministic light/dark Blue themes, Roboto, spacing/radius/elevation/focus/reduced-motion primitives and controlled Stitch asset provenance. Keep Green compatibility facades only for staged rollback. Admin remains an independent workspace theme.

## Wave 2 - Existing Stitch-referenced UI

Refactor consumer and Sale surfaces by group: onboarding/auth; dashboard/features/health score; schedule/meal/nutrition; chat/voice; profile/settings; V2/V3/payment/rewards; Sale. Preserve loading, empty, error, locked, pending, offline and retry behavior backed by real state.

## Wave 3 - Approved Guest/Free wellness surfaces

Expose the approved wellness pages and preserve Guest/member storage rules. `/health-tracking` remains an alias until the dedicated journal DD is Approved. Nami Care is a hub only for capabilities already present in runtime and must not invent expert or booking behavior.

## Wave 4 - M20-M29, OCR and health hubs

Implement only after module DD, clinical/privacy approval and platform capability review. Unsupported or unapproved capability fails closed with manual fallback or placeholder; no guessed schema or device contract.

## Wave 5 - AI, FamilyPlus chat and Sale expansion

Require approved backend safety, privacy, cryptography, retention and trusted RPC contracts. Do not call model services directly from new UI and do not expose health/raw payment data to Sale.

## Wave 6 - Cutover

Use `stitchGreenUi` separately from business flags. Blue is the default presentation in every build mode, but that does not mark the cutover complete. Do not call the cutover complete until all 76 Stitch references have recorded visual, dark, accessibility and adaptive evidence; retain `STITCH_GREEN_UI_ENABLED=true` as the Green compatibility rollback until its removal is explicitly approved.
