# Source Drift Notes

Baseline `d126e8ad0c482e3eacc373f35b37f339dd37a8cb`.

Verified re-execution findings:
- V1 router has 20 active routes.
- V2 router has 13 routes and combines V1/V2/V3.
- V3 router has 2 direct V3 routes.
- Admin router has login + 11 protected workspace routes.
- Daily Health Tracking delegates to Lifestyle Schedule.
- Sale lives at `lib/sale_referral/` and runtime shell has Overview/Customers/Points/Tools plus payout gate.
- Sleep, Stress and Community are coming-soon surfaces.
- FamilyPlus source exists without direct V3 route.
- Admin workspace routing uses `AdminWorkspacePage`; separate Admin shell/presentation files still exist.
