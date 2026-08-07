# Route Matrix

## Active route counts
- V1: 20 routes from `v1Routes`.
- V2: 13 routes from `v2Routes`.
- V3: 2 routes from `v3Routes`; standalone also reuses V1 Lifestyle Schedule.
- Admin: 12 routes (login + 11 protected workspace destinations); `/admin` redirects to dashboard.

## Important drift classification
- Daily Health Tracking route delegates to Lifestyle Schedule: alias, not independent visual product.
- Sleep/Stress/Community are development/coming-soon surfaces in current source.
- FamilyPlus page exists in source but is not a direct V3 route.
- Sale is under `lib/sale_referral/` and enters from V2 `/sale`.
- Admin protected routes share `AdminWorkspacePage` and workspace sections.
