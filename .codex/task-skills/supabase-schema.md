# Task Skill - Supabase schema and RLS

- Canonical key: supabase-schema
- Workflow: .codex/workflows/supabase-schema.md
- Generated from 13 worklog(s).

## When To Read

- Historical task type: Mo rong fixture Supabase local/sandbox, tai lieu va contract test. (1)
- Historical task type: coding/bugfix/test/docs (1)
- Historical task type: coding + Supabase schema draft + Admin UI + tests + docs (1)
- Historical task type: coding + Supabase contract + test + DD/docs. (1)
- Historical task type: bugfix + test (1)
- Historical task type: Supabase schema/seed fixture va smoke test (1)
- Historical task type: coding + Supabase schema draft + tests + DD/checklist docs (1)
- Historical task type: coding + Supabase schema draft + UI Sale + test/docs. (1)
- Historical task type: docs-context / audit checklist (1)
- Historical task type: docs/coding (1)
- Historical task type: coding + test + docs-context (1)
- Historical task type: coding + Supabase schema draft + test/docs. (1)
- Historical task type: coding + Supabase schema draft + test/docs (1)

## Common Modules

- Auth, subscription/quota, FamilyPlus, Sale, Admin, Wellness/reward, Nabi va Storage proof.: 1
- M02 PERSONAL_SCHEDULE_AI, M05 AUTH_PROFILE_SYNC, M06 MEMBERSHIP_QUOTA, M07 AI_CHAT, M09 SCHEDULE_NOTIFICATIONS, M15 ADMIN_DASHBOARD: 1
- M12 REFERRAL_DIRECT, M14 SALE_POINTS, Admin Sale conversion queue: 1
- M13 PAYMENT_MEMBERSHIP và Admin payment queue.: 1
- Sale/referral dashboard va direct customers: 1
- Sale/referral, M12 va M14: 1
- M15 ADMIN_DASHBOARD, M16 ADMIN_OPS, M17 RECONCILIATION, M18 REPORTING, M19 AUDIT_SECURITY: 1
- unknown: 1

## Work Pattern

- Start from the selected workflow, then this task skill, then one domain file.
- Prefer targeted `rg` and focused tests over broad reads/checks.
- Record exact evidence in the worklog and add the self-review section.
- Ask before expanding scope when BD/DD, issue/todo, or product decisions are missing.

## Token Optimization

- Ask: how can this task use fewer tokens while producing equal or better work?
- Read index/summary files before raw historical files.
- Stop reading when root cause, target files, and validation path are clear.
- Update this generated skill through the history refresh script, not by hand.

## Source Worklogs

- [Worklog - Supabase database draft](../../docs/worklog/2026-06-21/002-worklog-supabase-database-draft.md) - Supabase database, membership, quota, FamilyPlus, Sale/referral
- [Worklog - Audit module va flow san pham](../../docs/worklog/2026-06-22/006-worklog-module-flow-audit.md) - DB local, Supabase draft, lib/app_versions/v1, lib/app_versions/v2, lib/app_versions/v3, lib/sale_referral
- [Worklog - Cloud Sync Va Sale Interface](../../docs/worklog/2026-06-22/009-worklog-cloud-sync-sale.md) - unknown
- [Worklog - Admin App Surface Va Supabase Admin](../../docs/worklog/2026-06-28/003-worklog-admin-app-supabase.md) - Admin app, Supabase Admin, Sale direct-only
- [Worklog - Sale Module Full Noi Bo](../../docs/worklog/2026-06-28/004-worklog-sale-module-internal.md) - lib/sale_referral, lib/services/supabase/sale,
- [Worklog - Sale Repo-Ready M12 M14](../../docs/worklog/2026-06-28/007-worklog-sale-repo-ready.md) - M12 REFERRAL_DIRECT, M14 SALE_POINTS
- [Worklog - M15-M19 Admin Selected Policy](../../docs/worklog/2026-06-29/005-worklog-m15-m19-admin-selected-policy.md) - M15 ADMIN_DASHBOARD, M16 ADMIN_OPS, M17 RECONCILIATION, M18 REPORTING, M19 AUDIT_SECURITY
- [Worklog - Sale Module Production Policy](../../docs/worklog/2026-06-29/008-worklog-sale-module-production-policy.md) - M12 REFERRAL_DIRECT, M14 SALE_POINTS, Admin Sale conversion queue
- [Worklog - Ưu tiên Admin, khôi phục luồng AI và harden thông báo](../../docs/worklog/2026-07-19/001-worklog-admin-ai-notification-reliability.md) - M02 PERSONAL_SCHEDULE_AI, M05 AUTH_PROFILE_SYNC, M06 MEMBERSHIP_QUOTA, M07 AI_CHAT, M09 SCHEDULE_NOTIFICATIONS, M15 ADMIN_DASHBOARD
- [Worklog - Supabase comprehensive sandbox fixture](../../docs/worklog/2026-07-28/001-worklog-supabase-comprehensive-sandbox-fixture.md) - Auth, subscription/quota, FamilyPlus, Sale, Admin, Wellness/reward, Nabi va Storage proof.
- [Worklog - Sale A sandbox seed](../../docs/worklog/2026-07-28/002-worklog-sale-a-sandbox-seed.md) - Sale/referral, M12 va M14
- [Worklog - Sale dashboard RPC permission](../../docs/worklog/2026-07-28/003-worklog-sale-dashboard-rpc-permission.md) - Sale/referral dashboard va direct customers
