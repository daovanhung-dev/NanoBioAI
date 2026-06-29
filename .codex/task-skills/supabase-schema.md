# Task Skill - Supabase schema and RLS

- Canonical key: supabase-schema
- Workflow: .codex/workflows/supabase-schema.md
- Generated from 7 worklog(s).

## When To Read

- Historical task type: coding + Supabase schema draft + test/docs. (1)
- Historical task type: coding + test + docs-context (1)
- Historical task type: coding + Supabase schema draft + tests + DD/checklist docs (1)
- Historical task type: coding + Supabase schema draft + test/docs (1)
- Historical task type: docs/coding (1)
- Historical task type: docs-context / audit checklist (1)
- Historical task type: coding + Supabase schema draft + UI Sale + test/docs. (1)

## Common Modules

- lib/sale_referral, lib/services/supabase/sale,: 1
- M12 REFERRAL_DIRECT, M14 SALE_POINTS: 1
- M15 ADMIN_DASHBOARD, M16 ADMIN_OPS, M17 RECONCILIATION, M18 REPORTING, M19 AUDIT_SECURITY: 1
- Admin app, Supabase Admin, Sale direct-only: 1
- Supabase database, membership, quota, FamilyPlus, Sale/referral: 1
- DB local, Supabase draft, lib/app_versions/v1, lib/app_versions/v2, lib/app_versions/v3, lib/sale_referral: 1
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
