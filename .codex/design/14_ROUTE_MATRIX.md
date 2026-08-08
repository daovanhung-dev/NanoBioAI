# Route Matrix - working-tree snapshot 2026-08-08

## Direct route counts

- V1: **27** routes from `v1Routes`.
- V2: **13** routes from `v2Routes`.
- V3: **3** routes from `v3Routes`; the standalone router also reuses V1 Lifestyle Schedule.
- Admin: **12** routes (login plus 11 protected workspace destinations); `/admin` redirects to dashboard.

## Green Wellness route deltas

- `/today-tasks` is an active V1 route backed by `TodayTasksPage` and real Lifestyle Schedule state.
- `/water-tracking`, `/weekly-summary`, `/personal-goals`, `/quick-care` and `/gentle-care` now expose their existing V1 pages.
- `/nami-care` is an active hub that links only to the existing Water, Goals, Quick Care, Gentle Care and Weekly Summary pages; it does not add expert or booking behavior.
- `/v3/familyplus` exposes the existing FamilyPlus page behind authentication and effective-access protection.

## Important drift classification

- `/health-tracking` still delegates to Lifestyle Schedule: alias, not an independent wellness journal.
- Sleep, Stress and Community remain development/coming-soon surfaces in current source.
- FamilyPlus chat is not implied by the FamilyPlus page route and remains gated by DD/security/privacy approval.
- Sale remains under `lib/sale_referral/` and enters from V2 `/sale`.
- Admin protected routes share `AdminWorkspacePage` and the independent workspace theme.
