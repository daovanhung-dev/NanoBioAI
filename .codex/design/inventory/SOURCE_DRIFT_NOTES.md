# Source Drift Notes

Inventory baseline: `d126e8ad0c482e3eacc373f35b37f339dd37a8cb`.
Working-tree route refresh: 2026-08-08.

Current findings:

- V1 router has 27 direct routes after exposing Today Tasks and six wellness entries.
- V2 router has 13 direct routes and composes V1/V2/V3.
- V3 router has 3 direct V3 routes after exposing `/v3/familyplus`.
- Admin has login plus 11 protected workspace routes and keeps its independent workspace theme.
- `/today-tasks` uses `TodayTasksPage` and real Lifestyle Schedule state.
- `/water-tracking`, `/weekly-summary`, `/personal-goals`, `/quick-care` and `/gentle-care` expose existing pages.
- `/nami-care` is a concrete hub that links only to existing local wellness pages; no expert or booking capability is present.
- Daily Health Tracking still delegates to Lifestyle Schedule.
- Sleep, Stress and Community remain coming-soon surfaces.
- FamilyPlus is auth/effective-access protected; chat is not present merely because the page is routed.
- Sale remains under `lib/sale_referral/` with existing trusted behavior.

These route facts do not prove Stitch visual acceptance, new business capability or DD approval.
