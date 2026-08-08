# QA Checklist - Stitch Green Wellness

- Every accepted Stitch reference has classification, owner, route/state map and evidence.
- Goldens: light/dark at 390 x 884; adaptive widths 320/360/412/600+.
- Roboto is deterministic; no RenderFlex overflow at text scale 1.0/1.3/1.6.
- Contrast, screen-reader semantics, focus order, keyboard and >=48 dp targets pass.
- Reduce Motion/Transparency is usable and stable.
- Loading/empty/error/ready/locked/pending/offline/retry states are real where applicable.
- System back, deep link and route symmetry are preserved.
- No internal technical terms or sample personal/health/financial/QR data in user UI.
- Feedback timing follows the authoritative semantic result; duplicate submit is safe.
- Nabi does not obstruct controls.
- Admin retains its workspace palette and Sale/Admin financial data remains scannable.
- Asset provenance/license evidence exists; unverified assets remain reference-only.
- No 76/76 or production-ready claim without all applicable release gates.
