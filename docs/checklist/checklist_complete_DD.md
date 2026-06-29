# Checklist Complete DD

Commit de xuat: docs(checklist): tao checklist tien do DD

## Metadata

| Field | Value |
|---|---|
| Nguon | `docs/DD/README.md` va cac module `docs/DD/<module>/` |
| Pham vi | BioAI / NanoBio DD v2.0 M01-M19 |
| Loai tru | Module template folder, khong tinh vao M01-M19. |
| Ngay cap nhat | 2026-06-28 |
| Muc dich | Theo doi tien do DD readiness va coding progress de Agent chon dung module, dung blocker, dung buoc tiep theo khi coding. |

## Rubric phan tram

`DD readiness %`:

| % | Dieu kien |
|---:|---|
| 0 | Chua co DD module. |
| 20 | Co folder DD module nhung thieu file baseline hoac thieu mapping. |
| 40 | Co du baseline DD nhung con `Status: Draft`, open questions, hoac thieu contract/API/schema/RLS cu the. |
| 60 | Contract/API/schema/RLS du ro de coding phan khong bi blocker. |
| 80 | Ready/approved cho coding, acceptance criteria va test traceability da chot. |
| 100 | Implemented va accepted theo DD. |

`Coding progress %`:

| % | Dieu kien |
|---:|---|
| 0 | Chua co code runtime hoac backend lien quan. |
| 10 | Chi co placeholder/planned marker. |
| 25 | Co scaffold, UI, domain, hoac local service mot phan. |
| 40 | Co runtime local mot phan va tests muc tieu, nhung chua dung du DD. |
| 60 | Co integration/backend hoac SQL/RPC draft va app wiring mot phan. |
| 80 | Gan du acceptance path, co tests bao phu chinh, con thieu verification/edge cases. |
| 100 | Verified complete theo DD, co bang chung acceptance va khong con blocker. |

## Tong hop M01-M19

| Module | DD status | Open Q | DD readiness % | Coding progress % | Tien do hien tai | Blocker chinh | Buoc tiep theo |
|---|---|---:|---:|---:|---|---|---|
| M01 `ONBOARDING_PROFILE` | Draft | 2 | 40 | 60 | V1 onboarding local da duoc harden: local datasource co DB injection cho test, log onboarding da sanitize, completion handoff/mark completed/double-submit da co tests. | Supabase/profile sync contract, FamilyPlus subject/consent, health formula Q-14/Q-15 va DD approval chua chot. | Chot Q-14/Q-15 va Supabase/FamilyPlus contract truoc khi code cloud sync, subject member, consent policy nang cao, hoac health formula. |
| M02 `PERSONAL_SCHEDULE_AI` | Draft | 1 | 40 | 80 | Runtime local da co request ledger, guest initial plan one-time guard, retry idempotency, member quota gateway truoc AI, append generation khong ghi de lich cu, va targeted tests pass. | Trusted quota backend/RPC sandbox, FamilyPlus subject/ownership, Q-16 timezone approval, va DD approval van chua xong. | Chot/implement M06 trusted quota RPC + sandbox evidence; sau do wire production commit quota va FamilyPlus subject rules. |
| M03 `DASHBOARD_SCHEDULE` | Draft | 1 | 40 | 40 | V1 dashboard, timeline, lifestyle completion va related tests da co. | DD v2.0 dashboard state, data scope, va completion trace chua approved. | Map DD views/functions sang dashboard hien co, bo sung state/permission gaps va tests theo DD. |
| M04 `BASIC_HEALTH_CALC` | Draft | 1 | 40 | 40 | BMI/nutrition constants va local health calculator pieces da co. | Q-14 va copy/policy cho calculator output chua chot. | Chot calculator formulas/copy, gom services thanh contract ro, them tests theo acceptance DD. |
| M05 `AUTH_PROFILE_SYNC` | Draft | 2 | 40 | 60 | V2 auth, Supabase auth datasource, account security va cloud sync repository da co tests. | Guest merge/profile sync edge cases va access contract chua chot day du. | Doi chieu DD M05 voi v2 auth, them missing guest-sync cases va route/use-case guards. |
| M06 `MEMBERSHIP_QUOTA` | Draft | 2 | 40 | 60 | Co SQL draft membership/quota va placeholder v2 quota features. | Effective access, reset period, trusted quota write, va package policy chua approved. | Chot contract entitlement/quota, implement repository/RPC guard, them tests quota AI chat/schedule. |
| M07 `AI_CHAT` | Draft | 1 | 40 | 40 | V1 AI chat UI/service/repository da co. | Free quota 3 luot/ngay va entitlement gating chua wired truoc AI call. | Them quota check theo M06, tach safe error copy, test Free limit va Plus bypass. |
| M08 `HEALTH_SCORE_HABITS` | Draft | 2 | 40 | 40 | Co dashboard score/local health status va v2 health scoring local draft: domain service, SQLite read model, provider, route `/v2/health-score`, va targeted tests. | Q-14 official health formula/weights/skip-miss policy va Q-15 FamilyPlus subject/consent chua chot. | Chot Q-14/Q-15 truoc khi doi local draft thanh official scoring/ledger/backend contract. |
| M09 `SCHEDULE_NOTIFICATIONS` | Draft | 2 | 40 | 40 | Local notification scheduling, lifecycle, action handler va tests da co. | Family subject, permission lifecycle, va cross-device sync chua chot. | Doi chieu DD M09, them subject-aware contracts sau khi FamilyPlus scope duoc chot. |
| M10 `ADVANCED_TRACKING_GOALS` | Draft | 2 | 40 | 10 | V3 advanced tracking hien la planned placeholder. | Metrics, storage, paid access, va UI flows chua approved. | Chot DD contracts, tao vertical slice nho cho mot tracking metric truoc. |
| M11 `FAMILYPLUS` | Draft | 2 | 40 | 60 | Co FamilyPlus SQL draft va v3 family placeholders. | Role, invite/remove lifecycle, consent, member limits, va RLS smoke chua verified. | Chot family contract/RLS, implement repository + member UI slice, test cross-family isolation. |
| M12 `REFERRAL_DIRECT` | Draft | 5 | 40 | 80 | Sale direct-only repo-ready: registration pending Admin approval, active-only dashboard, referral attach RPC path, privacy-limited customer view, Admin Sale profile review va targeted tests. | Sale approval policy chi o muc repo contract; anti-fraud va Supabase sandbox/RLS/RPC evidence chua chot. | Verify SQL/RPC sandbox voi user A/B/Admin, chot anti-fraud/approval policy, sau do cap nhat DD acceptance evidence. |
| M13 `PAYMENT_MEMBERSHIP` | Draft | 5 | 40 | 60 | Co payment/membership SQL drafts va Admin trusted payment review RPC draft. | Provider webhook, refund/chargeback, entitlement activation, va Q-03..Q-05/Q-17 chua chot. | Chot provider/payment lifecycle, implement trusted backend path, test idempotency va no-client-payment-grant. |
| M14 `SALE_POINTS` | Draft | 8 | 40 | 80 | Sale ledger/conversion repo-ready: client chi doc trusted RPC, conversion request dung config/idempotency, Admin sale-conversion queue approve/reject/mark_paid qua RPC, SQL contract/tests da co. | Conversion/payout/reconciliation policy va Q-02..Q-10/Q-13 chua chot; SQL chua verify sandbox/staging. | Chay sandbox acceptance cho conversion queue, chot payout/refund/chargeback/reconciliation policy truoc production. |
| M15 `ADMIN_DASHBOARD` | Draft | 2 | 40 | 60 | Admin app surface, router, dashboard shell, Supabase RPC datasource, permission-denied state, nav/action filtering va contract tests da co. | Admin role matrix Q-12, privacy Q-18, `plans.write` vs `config.write` matrix gap, va SQL sandbox verification chua xong. | Chot role matrix Q-12/Q-18 va `plans.write` policy, verify Admin SQL/RPC sandbox, ghi acceptance evidence. |
| M16 `ADMIN_OPS` | Draft | 4 | 40 | 60 | Admin sections users/payments/sales/plans/reports/audit/config, mutation command path, client-side mutation permission guard va controller tests da co. | Permission matrix, reason policy, audit completeness, operation-specific contracts, va sandbox RLS/RPC checks chua approved. | Chot each admin operation contract, verify sandbox RLS/RPC va audit rows per mutation. |
| M17 `RECONCILIATION` | Draft | 4 | 40 | 25 | Co mot so ledger/payment/sale SQL draft, chua co reconciliation module runtime rieng. | Financial reconciliation Q-02..Q-10/Q-17 va provider data model chua chot. | Chot reconciliation source of truth, tao read model/RPC draft, test mismatch/refund/chargeback cases. |
| M18 `REPORTING` | Draft | 3 | 40 | 60 | Admin report export table/RPC draft va reports section da co. | Reporting scope, anonymization, export approval, va retention chua chot. | Chot report catalog, implement export request lifecycle, test permission and privacy filters. |
| M19 `AUDIT_SECURITY` | Draft | 3 | 40 | 60 | Admin audit events table/RPC draft, audit section, va contract tests da co. | Audit taxonomy, retention, support scope, va security response policy chua approved. | Chot audit event schema, enforce audit on sensitive mutations, test no raw PII/payment evidence exposure. |

## Chi tiet module va next steps

| Module | Bang chung hien co | Con thieu de dat DD | Next steps chi tiet |
|---|---|---|---|
| M01 `ONBOARDING_PROFILE` | `lib/app_versions/v1/features/onboarding/`, `test/app_versions/v1/features/onboarding/onboarding_local_datasource_test.dart`, `test/app_versions/v1/features/onboarding/onboarding_completion_flow_test.dart` | Supabase/profile sync contract, FamilyPlus subject/consent, health formula Q-14/Q-15, DD approval. | 1. Chot Q-14/Q-15. 2. Chot Supabase/profile sync va FamilyPlus subject contract. 3. Sau do tao issue/test cho cloud sync, subject member, consent policy nang cao neu nam trong M01. |
| M02 `PERSONAL_SCHEDULE_AI` | `lib/app_versions/v1/services/ai/generated_plan_service.dart`, `lib/app_versions/v1/services/ai/generated_plan_request_store.dart`, `lib/app_versions/v1/services/ai/personal_schedule_quota_gateway.dart`, SQLite v10 request ledger, generated plan/migration/dashboard tests. | Trusted M06 quota RPC/RLS sandbox, production quota commit evidence, FamilyPlus subject/ownership, DD approval. | 1. Chot Q-16 va trusted quota RPC contract. 2. Verify M06 sandbox/RLS. 3. Sau do replace unavailable default adapter bang backend quota implementation va them FamilyPlus subject tests. |
| M03 `DASHBOARD_SCHEDULE` | `lib/app_versions/v1/features/dashboard/`, lifestyle schedule completion tests. | DD v2 state mapping, permission/data scope, final acceptance matrix. | 1. Map DD views to current dashboard widgets. 2. Identify missing states. 3. Add targeted widget/domain tests. |
| M04 `BASIC_HEALTH_CALC` | `lib/core/constants/health/`, dashboard health calculator/service tests. | Approved formulas and user-facing safe copy. | 1. Chot Q-14. 2. Promote formulas into tested services. 3. Add validation/error cases. |
| M05 `AUTH_PROFILE_SYNC` | `lib/app_versions/v2/features/auth/`, `lib/services/supabase/auth/`, cloud sync tests. | Guest merge and profile sync rules across devices. | 1. Compare DD M05 with existing auth route resolver. 2. Add missing sync repository tests. 3. Update Supabase contract docs if needed. |
| M06 `MEMBERSHIP_QUOTA` | `docs/supabase/03-membership-quota.sql`, v2 quota placeholders. | Effective access service, trusted quota RPC, reset policy. | 1. Chot entitlement/quota rules. 2. Implement repository/service guard. 3. Add quota tests for AI chat and schedule. |
| M07 `AI_CHAT` | `lib/app_versions/v1/features/ai_chat/`, `lib/app_versions/v1/services/ai/ai_chat_service.dart`. | Quota and package gate before AI calls. | 1. Wire M06 quota service. 2. Add safe blocked state UI. 3. Test Free daily limit and paid bypass. |
| M08 `HEALTH_SCORE_HABITS` | Dashboard health status, `lib/app_versions/v2/features/health_scoring/`, `/v2/health-score`, va `test/app_versions/v2/features/health_scoring/`. | Official score formula, persisted ledger/backend contract, skip/miss schema, va FamilyPlus subject model. | 1. Chot Q-14/Q-15. 2. Replace local draft formula bang official versioned formula. 3. Add ledger/RLS/backend acceptance neu production scope duoc approve. |
| M09 `SCHEDULE_NOTIFICATIONS` | `lib/app_versions/v1/services/notifications/`, notification tests. | Family/subject-aware notification rules and sync policy. | 1. Chot M11 dependency. 2. Add subject metadata contract. 3. Test permission denied and lifecycle refresh. |
| M10 `ADVANCED_TRACKING_GOALS` | `lib/app_versions/v3/features/advanced_health_tracking/advanced_health_tracking.dart`. | Real feature contract, storage, UI, paid access. | 1. Chot first paid tracking metric. 2. Implement one vertical slice. 3. Add repository and UI tests. |
| M11 `FAMILYPLUS` | `docs/supabase/04-family-plus.sql`, v3 family placeholders. | Member lifecycle, consent, RLS verification, UI/repository. | 1. Chot family roles/invite/remove. 2. Implement member repository/UI slice. 3. Run RLS smoke for two families. |
| M12 `REFERRAL_DIRECT` | `lib/sale_referral/`, `lib/app_versions/admin/`, `docs/supabase/12-sale-module-update.sql`, `test/sale_referral/`, `test/app_versions/admin/admin_models_test.dart` | Sandbox RPC evidence, anti-fraud, final Sale approval policy. | 1. Chay SQL 12 sandbox. 2. Smoke user A request Sale -> Admin approve/reject/suspend -> referral attach. 3. Ghi privacy/audit evidence vao DD. |
| M13 `PAYMENT_MEMBERSHIP` | `docs/supabase/05-sale-referral-commission.sql`, `docs/supabase/11-admin-access-dashboard.sql`. | Provider webhook, entitlement activation, refund/chargeback handling. | 1. Chot payment provider and states. 2. Implement trusted payment recorder outside Flutter. 3. Test idempotency and admin approval. |
| M14 `SALE_POINTS` | Sale point ledger/conversion SQL, Sale app conversion request, Admin sale-conversion queue, targeted tests. | Final payout/reconciliation policy, refund/chargeback handling, sandbox RPC/RLS evidence. | 1. Verify conversion config/request/review RPC in sandbox. 2. Chot Q-02..Q-10/Q-13. 3. Sau do them reconciliation/refund acceptance neu duoc unlock. |
| M15 `ADMIN_DASHBOARD` | `lib/app_versions/admin/`, `docs/supabase/11-admin-access-dashboard.sql`, `test/app_versions/admin/`, admin/docs contract tests. | Final role matrix, privacy scope, `plans.write` vs `config.write` decision, sandbox SQL/RPC verification. | 1. Chot Q-12/Q-18 va plans/config permission policy. 2. Verify Admin SQL/RPC sandbox. 3. Ghi acceptance evidence dashboard metric theo permission. |
| M16 `ADMIN_OPS` | Admin sections, mutation command path, permission guard va controller tests trong `lib/app_versions/admin/` va `test/app_versions/admin/`. | Operation-level permissions, reason policy, audit completeness, sandbox RLS/RPC evidence. | 1. Define each admin operation contract. 2. Verify audit rows per mutation in sandbox. 3. Them operation-specific acceptance tests sau khi contract duoc chot. |
| M17 `RECONCILIATION` | Related payment/sale ledger SQL drafts. | Dedicated reconciliation read model, mismatch policy, provider data. | 1. Chot reconciliation source of truth. 2. Draft RPC/read model. 3. Test mismatch, refund, chargeback, duplicate event cases. |
| M18 `REPORTING` | Admin report export SQL/RPC draft and reports section. | Report catalog, export lifecycle, privacy filters. | 1. Chot report list and scopes. 2. Implement export request flow. 3. Test permission, anonymization, retention. |
| M19 `AUDIT_SECURITY` | Admin audit events SQL/RPC and audit UI section. | Audit taxonomy, retention, security/support policy. | 1. Chot event taxonomy. 2. Require audit for all sensitive mutations. 3. Test no secret/PII/raw payment evidence in logs. |

## Quy tac Agent khi coding

- Truoc khi coding: doc file nay de xac dinh module, phan tram hien tai, blocker, va next step.
- Sau do doc `docs/checklist/checklist_task_coding.md` de lay note cong viec tu phien truoc.
- Neu module van `Draft` va blocker anh huong truc tiep den behavior, khong invent behavior; ghi gap vao checklist/worklog.
- Sau khi coding: cap nhat lai phan tram, bang chung, next steps trong file nay va ghi viec tiep theo vao `docs/checklist/checklist_task_coding.md`.
