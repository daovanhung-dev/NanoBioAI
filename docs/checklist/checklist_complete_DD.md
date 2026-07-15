# Checklist Complete DD

Commit de xuat: docs(checklist): danh dau DD docs M01-M19 hoan thanh 100 phan tram

## Metadata

| Field | Value |
|---|---|
| Nguon | `docs/DD/README.md`, cac module `docs/DD/<module>/`, Approved addendum `BD-BIOAI-WELLNESS-REWARDS-001`, va Advanced Health BD `BD-BIOAI-ADVANCED-HEALTH-001` |
| Pham vi | BioAI / NanoBio: approved DD M01-M19, Approved delta daily proof/wellness rewards cho M03/M08/M09/M15/M16, va planned DD backlog M20-M29 |
| Loai tru | Module template folder; UI catalog shell/placeholder khong tinh vao DD completeness hoac business coding progress. |
| Ngay cap nhat | 2026-07-15 |
| Muc dich | Theo doi DD docs completeness rieng voi coding progress va implementation evidence backlog; khong tron UI discovery shell voi nghiep vu module. |

## Rubric phan tram

`DD completeness %`:

| % | Dieu kien |
|---:|---|
| 0 | Chua co DD module. |
| 20 | Co folder DD module nhung thieu file baseline hoac thieu mapping. |
| 40 | Co du baseline DD nhung con open questions hoac thieu contract/API/schema/RLS/test traceability trong tai lieu. |
| 60 | Contract/API/schema/RLS da co mot phan nhung chua du de coding khong can hoi lai. |
| 80 | Product decisions, acceptance criteria, API/schema/RLS va test traceability da du cho targeted coding. |
| 100 | DD docs approved: status Approved, Open Q = 0, rule/API/schema/RLS/test traceability documented, approval checklist docs pass. |

`Coding progress %`: chi doi khi co bang chung code runtime, test, SQL/RPC, sandbox hoac acceptance thuc te.

## Tong hop M01-M29

| Module | DD docs status | Open Q | DD completeness % | Coding progress % | DD docs evidence | Implementation evidence backlog | Next implementation evidence |
|---|---|---:|---:|---:|---|---|---|
| M01 `ONBOARDING_PROFILE` | Approved - DD docs complete | 0 | 100 | 100 | V1 onboarding local hardening, authenticated local-first completion, outbox marker, snapshot tests, and shared `SubjectAccessContext` subject override tests exist. | Supabase sandbox/RLS profile sync evidence and consent/audit smoke evidence remain production acceptance backlog. | Smoke authenticated onboarding/profile sync in Supabase sandbox and verify consent/audit evidence. |
| M02 `PERSONAL_SCHEDULE_AI` | Approved - DD docs complete | 0 | 100 | 100 | Local request ledger, guest guard, idempotency, quota gateway, month-boundary/request-id tests, trusted quota RPC wrappers, and Asia/Ho_Chi_Minh adapter alignment exist. | Supabase sandbox/RLS quota execution and FamilyPlus subject ownership smoke remain production acceptance backlog. | Execute schedule quota check/commit RPCs in Supabase sandbox and verify Free, Plus, and FamilyPlus behavior with M06/M11. |
| M03 `DASHBOARD_SCHEDULE` | Approved - DD docs complete | 0 | 100 | 100 | Dashboard, timeline, lifestyle completion, subject-aware datasource mapping, and FamilyPlus/non-FamilyPlus tests exist. | Supabase sandbox cross-member visibility and RLS smoke remain production acceptance backlog. | Verify dashboard subject visibility and traceability in sandbox. |
| M04 `BASIC_HEALTH_CALC` | Approved - DD docs complete | 0 | 100 | 100 | Versioned BMI/BMR/RMR/TDEE/hydration calculator, route `/body-metrics`, hub tile, disclaimer UI, and unit/widget tests exist. | Clinical/formula source review and production copy approval remain production acceptance backlog. | Verify production copy/formula references with PO/clinical review before release. |
| M05 `AUTH_PROFILE_SYNC` | Approved - DD docs complete | 0 | 100 | 100 | Auth callback coordinator/result, reactive gate/router, Guest Settings login/register entry, authenticated build helper, sign-out preflight, atomic referral signup metadata, Guest consent, single-flight push-before-pull sync, durable pull retry, transaction race guard, Admin session isolation, request-ledger `request_id` snapshot mapping, migration and focused regression/contract test source exist. | Flutter compile/full test, Supabase sandbox atomic rollback/RLS/idempotency and device `12b304f9` evidence remain production acceptance backlog; no concurrent multi-device merge support. | Run targeted/full Flutter gates, apply migration 15 to sandbox, execute `V2-M05-01..06`, callback recovery/confirmation and Admin role/session-expiry cases with evidence. |
| M06 `MEMBERSHIP_QUOTA` | Approved - DD docs complete | 0 | 100 | 100 | SQL quota RPC contracts, v2 effective access read model, shared trusted quota gateway, Free 3/day and 3/month static contract tests, paid bypass tests, Asia/Ho_Chi_Minh period keys, idempotent commit, and no-client-write checks exist. | Supabase sandbox/RLS verification for quota counters/events, idempotency, reset policy, and client write rejection remains production acceptance backlog. | Run `docs/supabase/config.sql` in sandbox and execute quota acceptance checks for Free, Plus, and FamilyPlus accounts. |
| M07 `AI_CHAT` | Approved - DD docs complete | 0 | 100 | 100 | AI Chat repository checks quota before AI, commits only after successful response, maps safe blocked states, and has quota tests for Free daily limit and paid bypass contract. | Sandbox proof that Free limit blocks after 3/day and Plus/FamilyPlus bypass via M06 RPC remains production acceptance backlog. | Smoke AI Chat with authenticated Free and paid sandbox users, verifying no AI call when quota is denied. |
| M08 `HEALTH_SCORE_HABITS` | Approved - DD docs complete | 0 | 100 | 100 | Official `m08_wellness_v1_2026_06` formula, Vietnamese UI/disclaimer, FamilyPlus subject access tests, Supabase `health_score_ledgers` contract/RLS, providers, route, and tests exist. | Supabase sandbox ledger/RLS smoke remains production acceptance backlog. | Verify health score ledger read/write policy and FamilyPlus visibility in sandbox. |
| M09 `SCHEDULE_NOTIFICATIONS` | Approved - DD docs complete | 0 | 100 | 100 | Subject-aware notification payload v2, subject-stable reminder IDs, idempotent action handling, source-owner mismatch protection, permission-denied/refresh/package-member tests, cloud-sync contract, and architecture tests pass. | Production real-device notification and Supabase sandbox cross-device smoke remain outside code+test acceptance. | Run real-device notification delivery/action smoke and Supabase sandbox sync before production release. |
| M10 `ADVANCED_TRACKING_GOALS` | Approved - DD docs complete | 0 | 100 | 100 | V3 hydration advanced tracking slice implemented with Plus/FamilyPlus access gate, `advanced_hydration` goal storage in `health_goals`, roadmap progress from `health_tracking_logs.water_ml`, v3 route/page/providers/repository/use cases, widget/provider/data/use-case tests, cloud-sync contract, and architecture tests pass. | Production paid-access sandbox and FamilyPlus subject/RLS smoke remain outside code+test acceptance. | Run sandbox Plus/FamilyPlus access and subject visibility smoke before production release. |
| M11 `FAMILYPLUS` | Approved - DD docs complete | 0 | 100 | 100 | V3 FamilyPlus runtime slice, route `/v3/familyplus`, domain/repository/providers/page, SQL/RPC contracts, owner-managed writes, max-5 member guard, idempotency keys, `SubjectAccessContext`, and focused tests exist. | Supabase sandbox member lifecycle, RLS isolation, and two-family visibility evidence remain production acceptance backlog. | Verify member lifecycle, selected subject context, and two-family isolation in Supabase sandbox. |
| M12 `REFERRAL_DIRECT` | Approved - DD docs complete | 0 | 100 | 100 | Sale direct-only runtime/tests, privacy-limited Sale DTOs, registration-only referral attach contract, and anti-fraud blockers for self-referral, duplicate relationship, inactive Sale, device/email/phone collision, and payment-history lock exist. | Supabase RPC/RLS sandbox evidence and live anti-fraud smoke cases remain production acceptance backlog. | Smoke Sale request, Admin approval/suspend, referral attach, fraud hold, and privacy DTOs in Supabase sandbox. |
| M13 `PAYMENT_MEMBERSHIP` | Approved - DD docs complete | 0 | 100 | 100 | V2 payments feature, client-safe pending payment RPC `create_membership_payment_request`, idempotency, price config, no pending-rights grant, 24h reversal guard, and targeted tests exist. | Provider/sandbox payment approval, entitlement activation, and external payment evidence remain production acceptance backlog. | Test manual payment approval, provider callback, entitlement activation, and 24h cancel/refund in sandbox. |
| M14 `SALE_POINTS` | Approved - DD docs complete | 0 | 100 | 100 | Sale ledger/conversion request, Admin queue, SQL contracts, privacy-limited direct customer DTO/UI, minimum conversion 500000 VND, and tests are repo-ready. | Sandbox conversion queue, payout audit, and reconciliation edge evidence remain production acceptance backlog. | Verify 24h hold, minimum conversion, manual payout, Super Admin adjustment, suspended Sale, and FamilyPlus owner-only cases. |
| M15 `ADMIN_DASHBOARD` | Approved - DD docs complete | 0 | 100 | 100 | Admin dashboard runtime/SQL has support/content roles, operations legacy alias, expanded safe summary metrics, drill-down target sections, timezone default, and privacy-limited summaries. | Admin SQL/RPC/RLS and audit-safe metric evidence remain production acceptance backlog. | Verify Admin roles, dashboard metrics, drill-down target sections, and privacy DTOs in sandbox. |
| M16 `ADMIN_OPS` | Approved - DD docs complete | 0 | 100 | 100 | Admin ops covers users, payments, sales, sale conversions, reconciliation, plans, reports, audit, config, manual payment approval, audited point adjustment, payment reversal mapping, report catalog, reason/idempotency, and targeted tests. | Sandbox mutation/RLS/audit evidence remains production acceptance backlog. | Run mutation RPCs with role checks, reason/idempotency, audit rows, and client write rejection. |
| M17 `RECONCILIATION` | Approved - DD docs complete | 0 | 100 | 100 | Reconciliation UI/RPC mapping includes section-level `create_run`, status updates, 24h hold contracts, suspended/closed Sale policy, Super Admin adjustment, no ledger overwrite, and focused tests. | Provider/staging discrepancy data and sandbox edge cases remain production acceptance backlog. | Test pending payment mismatch, refund/cancel, held points, suspended Sale, and manual approval evidence. |
| M18 `REPORTING` | Approved - DD docs complete | 0 | 100 | 100 | Safe report catalog, fixed report types, `admin_list_report_catalog`, privacy-limited export filters, `p_report_type = targetId`, Vietnam timezone, audit, and static contract tests exist. | Retention policy execution and sandbox export evidence remain production acceptance backlog. | Verify export request audit, privacy filters, no raw payloads, retention, and timezone windowing in sandbox. |
| M19 `AUDIT_SECURITY` | Approved - DD docs complete | 0 | 100 | 100 | Audit/security contracts cover Admin groups, Super Admin sensitive edits, point adjustment, reconciliation classify, reason/idempotency requirements, audit writes, and DTO tests blocking raw metadata, secrets, raw payment evidence, and health payloads. | Security response, retention, and sandbox audit rows remain production acceptance backlog. | Verify audit rows for payment, Sale, reconciliation, point adjustment, Admin list privacy, and retention in sandbox. |
| M20 `BLOOD_PRESSURE_TRACKING` | Not started - source BD Draft | AHF-Q open | 0 | 0 | Detailed BD M20/UC-25 exists; only catalog shell is approved. No DD folder or business implementation evidence. | Clinical source/threshold, data lifecycle, FamilyPlus, schema/API/RLS and test design are unresolved. | Resolve relevant AHF-Q items, create and approve DD before business coding. |
| M21 `HEART_OXYGEN_TRACKING` | Not started - source BD Draft | AHF-Q open | 0 | 0 | Detailed BD M21/UC-26 exists; only catalog shell is approved. No DD folder or business implementation evidence. | Device accuracy/limitation, escalation, data lifecycle, schema/API/RLS and tests are unresolved. | Approve safety/device policy, then create DD. |
| M22 `MEDICATION_ADHERENCE` | Not started - source BD Draft | AHF-Q open | 0 | 0 | Detailed BD M22/UC-27 exists; only catalog shell is approved. No DD folder or business implementation evidence. | Medication boundary, schedule versioning, M09 reminder contract, privacy and tests are unresolved. | Approve medication/reminder policy, then create DD. |
| M23 `GLUCOSE_TRACKING` | Not started - source BD Draft | AHF-Q open | 0 | 0 | Detailed BD M23/UC-28 exists; only catalog shell is approved. No DD folder or business implementation evidence. | Unit/threshold/clinical policy, entitlement, data lifecycle, RLS and tests are unresolved. | Approve clinical/access policy, then create DD. |
| M24 `SYMPTOM_PAIN_JOURNAL` | Not started - source BD Draft | AHF-Q open | 0 | 0 | Detailed BD M24/UC-29 exists; only catalog shell is approved. No DD folder or business implementation evidence. | Escalation, free-text privacy, symptom catalog, AI boundary and tests are unresolved. | Approve safety/privacy policy, then create DD. |
| M25 `WOMENS_CYCLE_HEALTH` | Not started - source BD Draft | AHF-Q open | 0 | 0 | Detailed BD M25/UC-30 exists; only catalog shell is approved. No DD folder or business implementation evidence. | Sensitive data, minor/pregnancy, FamilyPlus disclosure/revoke, retention/delete and tests are unresolved. | Approve privacy/clinical policy, then create DD. |
| M26 `RESPIRATORY_ALLERGY_TRACKING` | Not started - source BD Draft | AHF-Q open | 0 | 0 | Detailed BD M26/UC-31 exists; only catalog shell is approved. No DD folder or business implementation evidence. | Action-plan/escalation, trigger catalog, device/source, privacy and tests are unresolved. | Approve respiratory safety policy, then create DD. |
| M27 `LAB_RESULT_TRACKING` | Not started - source BD Draft | AHF-Q open | 0 | 0 | Detailed BD M27/UC-32 exists; only catalog shell is approved. No DD folder or business implementation evidence. | Unit/reference/source, correction, user-confirmed AI extraction, OCR/import boundary, retention/export and tests are unresolved. | Approve lab data and AI-extraction confirmation policy, then create DD. |
| M28 `PREVENTIVE_CARE` | Not started - source BD Draft | AHF-Q open | 0 | 0 | Detailed BD M28/UC-33 exists; only catalog shell is approved. No DD folder or business implementation evidence. | Vietnam locale/source/version, minor/pregnancy, reminder and test policy are unresolved. | Approve preventive source policy, then create DD. |
| M29 `AI_HEALTH_TRENDS` | Not started - source BD Draft | AHF-Q open | 0 | 0 | Detailed BD M29/UC-34 exists; only catalog shell is approved. No DD folder, AI contract or business implementation evidence. | Consent, minimum data, model/prompt policy, safety evaluation, quota, audit, retention and tests are unresolved. | Approve M06/M07/M19 AI contract and create DD before any production AI call. |

## Accepted Decision Coverage

| Decision group | DD docs status | Implementation note |
|---|---|---|
| Q-01..Q-18 | Closed and approved in DD docs | Recorded in `docs/DD/README.md`, module README/Overall contracts, and changelogs on 2026-06-30. |
| Health formulas Q-14 | Approved for DD docs | Wellness-reference only; production must keep version config and disclaimer copy. |
| Sale/payment/payout | Approved for DD docs | Manual payment/payout approval, 24h hold, 24h refund/cancel, listed-price commission, owner-only FamilyPlus commission. |
| Admin/privacy | Approved for DD docs | Full Admin group model, Super Admin-only sensitive edits, Sale privacy-limited phone/basic customer info. |
| Advanced Health M20-M29 | BD Draft; UI catalog shell approved only | M20-M29 DD completeness 0% and business coding progress 0%; placeholder UI is not feature completion. |

## Implementation Evidence Backlog

### Cap nhat implementation evidence 2026-07-15 — logbug 14-7-26

- M01: thêm daily routine versioned `daily_routine_v1`, onboarding/legacy editor, stable survey answer và outbox hiện có.
- M02: thêm horizon gate inclusive, malformed fail-closed, idempotent replay, per-user single-flight và resolver-owned timing.
- M03: dashboard dùng chung horizon, completion/undo inclusive đến đúng `+30 phút`, camera recheck và invalid-time lock.
- M07: runtime defines thống nhất, AI typed fail-closed và commit quota retry ba lần cùng request id.
- M09: reminder dùng schedule time đã resolve; không đổi notification mechanism.
- DD/coding progress vẫn 100% theo source + targeted tests; production acceptance vẫn thiếu Supabase sandbox/Storage/RLS/concurrency và real-device smoke.
- Logbug progress theo trọng số 50/30/20 hiện `90%`: DD 50/50, code 30/30, verification 10/20.

### Cập nhật implementation evidence 2026-07-13 — nhiệm vụ, proof và Điểm chăm sóc

DD M03/M08/M09/M15/M16 vẫn `Approved - DD docs complete` và coding progress
vẫn 100%. Addendum `BD-BIOAI-WELLNESS-REWARDS-001` đã chốt toàn bộ quyết định
nghiệp vụ của delta; không còn open product question cho phạm vi này. Tỷ lệ 100%
không đồng nghĩa production acceptance.

| Module | Source/targeted evidence mới | Evidence còn thiếu trước production |
|---|---|---|
| M03 `DASHBOARD_SCHEDULE` | Time policy `[start, start + 30 phút]`, fail-closed parser, camera/JPEG/EXIF proof, app-private gallery, SQLite v14 sidecar/cache, online begin/upload/finalize/undo/reconcile, dashboard/deep-link và focused tests đã có source. Daily/proof analyze sạch; 59 lifestyle/migration/notification/cloud-sync + 50 dashboard bundle và EXIF tests pass. Supabase contract 40 test, full `config.sql` rebuild PostgreSQL 18 tạm, local end-to-end/RLS/direct-ledger smoke PASS. | Deploy migration 16/bucket vào Supabase sandbox thật, kiểm tra runtime Storage/RLS hai user, exact-end/upload/finalize/two-device concurrency, account-deletion cleanup và real-device camera/resume/cloud-download smoke. |
| M08 `HEALTH_SCORE_HABITS` | DD delta tách Điểm sức khỏe, Điểm chăm sóc và Điểm Sale; local completion/proof/health projection transaction và legacy history non-redeemable có source contract. Full config rebuild và local reward/RLS/direct-ledger smoke PASS. | Sandbox thật chứng minh ledger/snapshot tách biệt, legacy không vào redeem balance và FamilyPlus/owner visibility. |
| M09 `SCHEDULE_NOTIFICATIONS` | Copy `Mở để chụp ảnh`, payload/owner validation, navigation coordinator và exact-item deep-link dùng M03 proof use case; notification bundle nằm trong 59 test pass. | Android/iOS foreground/background/terminated real-device smoke và Supabase cross-device reconcile. |
| M15 `ADMIN_DASHBOARD` | Admin section/route `Điểm chăm sóc`, `wellness_rewards.read/write`, safe Vietnamese permission/action/audit mapping và reward Admin tests có source; reward bundle 38/38 + targeted analyze pass; Supabase contract/rebuild/local RLS smoke PASS. | Sandbox thật cho role matrix, privacy-limited response, inventory aggregate và denied-route/API evidence. |
| M16 `ADMIN_OPS` | Catalog upsert, bulk code import, inventory/redemption list, cancel/refund UI/RPC contract, reason/idempotency/audit và append-only/revoke DML SQL source đã có. Supabase 40 contract tests, full config rebuild và local redeem/cancel/RLS smoke PASS. | Apply migration 16 trong sandbox thật; chạy row-lock/concurrency, duplicate/invalid import, cancel/refund exactly-once, audit row và direct DML rejection. |
| Cross-cutting localization | `vi_VN` app roots, l10n/ARB, preference migration, permission copy, Vietnamese mapper/scanner source; 96 targeted + 54 localization/settings/image tests, targeted analyze và contract scan pass. | Full repo validation và visual/accessibility/device review; OS-owned permission buttons remain device-language dependent. |

Rollout gate: `wellness_rewards_rollout.enabled` phải giữ `false` cho đến khi
migration 16, private bucket runtime, RLS, catalog/inventory seed và smoke
acceptance đạt trên một dự án Supabase sandbox thật.

| Module | Required implementation evidence before production acceptance |
|---|---|
| M01 `ONBOARDING_PROFILE` | Supabase sandbox/RLS profile sync evidence and consent/audit smoke evidence. |
| M02 `PERSONAL_SCHEDULE_AI` | Supabase sandbox/RLS quota execution and FamilyPlus subject ownership smoke. |
| M03 `DASHBOARD_SCHEDULE` | Supabase sandbox cross-member visibility and RLS smoke evidence. |
| M04 `BASIC_HEALTH_CALC` | Clinical/formula source review and production copy approval evidence. |
| M05 `AUTH_PROFILE_SYNC` | Flutter compile/full test, guest consent/push-before-pull cross-device sandbox evidence, request ledger round-trip, atomic invalid-referral rollback, RLS/idempotency and Admin separate-session/device evidence. |
| M06 `MEMBERSHIP_QUOTA` | Supabase sandbox/RLS verification for quota counters/events, idempotency, reset policy, and client write rejection. |
| M07 `AI_CHAT` | Sandbox proof that Free limit blocks after 3/day and Plus/FamilyPlus bypass via M06 RPC. |
| M08 `HEALTH_SCORE_HABITS` | Supabase sandbox ledger/RLS smoke evidence. |
| M09 `SCHEDULE_NOTIFICATIONS` | Production real-device notification delivery/action smoke and Supabase sandbox cross-device sync evidence before release. |
| M10 `ADVANCED_TRACKING_GOALS` | Production Plus/FamilyPlus sandbox access, subject visibility/RLS, and hydration roadmap smoke before release. |
| M11 `FAMILYPLUS` | Supabase sandbox member lifecycle, selected subject context, RLS isolation, and two-family visibility evidence. |
| M12 `REFERRAL_DIRECT` | Supabase RPC/RLS sandbox evidence and live anti-fraud smoke cases. |
| M13 `PAYMENT_MEMBERSHIP` | Provider/sandbox payment approval, entitlement activation, and external payment evidence. |
| M14 `SALE_POINTS` | Sandbox conversion queue, payout audit, and reconciliation edge evidence. |
| M15 `ADMIN_DASHBOARD` | Admin SQL/RPC/RLS and audit-safe metric evidence. |
| M16 `ADMIN_OPS` | Sandbox mutation/RLS/audit evidence. |
| M17 `RECONCILIATION` | Provider/staging discrepancy data and sandbox edge cases. |
| M18 `REPORTING` | Retention policy execution and sandbox export evidence. |
| M19 `AUDIT_SECURITY` | Security response, retention, and sandbox audit rows evidence. |
| M20 `BLOOD_PRESSURE_TRACKING` | First approve DD, clinical/source policy, manual data contract, FamilyPlus/RLS and tests; then collect implementation/sandbox evidence. |
| M21 `HEART_OXYGEN_TRACKING` | First approve DD, device limitation/escalation policy, manual data contract, FamilyPlus/RLS and tests. |
| M22 `MEDICATION_ADHERENCE` | First approve DD, no-prescribing boundary, schedule/event/M09 contract, privacy/RLS and tests. |
| M23 `GLUCOSE_TRACKING` | First approve DD, clinical/unit/threshold policy, entitlement, FamilyPlus/RLS and tests. |
| M24 `SYMPTOM_PAIN_JOURNAL` | First approve DD, escalation/free-text/AI boundary, FamilyPlus/RLS and tests. |
| M25 `WOMENS_CYCLE_HEALTH` | First approve DD, sensitive/minor/FamilyPlus/revoke/retention policy, RLS and tests. |
| M26 `RESPIRATORY_ALLERGY_TRACKING` | First approve DD, action-plan/escalation/source policy, FamilyPlus/RLS and tests. |
| M27 `LAB_RESULT_TRACKING` | First approve DD, original unit/range/source, user-confirmed AI extraction, import/retention policy, RLS and tests. |
| M28 `PREVENTIVE_CARE` | First approve DD, Vietnam source/version policy, M09 reminder contract, FamilyPlus/RLS and tests. |
| M29 `AI_HEALTH_TRENDS` | First approve DD and M06/M07/M19 consent/quota/safety/evaluation/provenance contract before AI implementation evidence. |

## Quy tac Agent khi coding

- Truoc khi coding: doc file nay de xac dinh DD module, coding progress hien tai, implementation evidence backlog va next step.
- Sau do doc `docs/checklist/checklist_task_coding.md` de lay note cong viec tu phien truoc.
- Q-01..Q-18 khong con la PO blocker; khong invent rule khac neu conflict voi accepted decision registry.
- DD completeness da la 100% cho M01-M19; chi tang coding progress khi co code/test/SQL/sandbox evidence moi.
- M20-M29 hien co DD completeness 0% va business coding progress 0%. UI catalog shell/placeholder khong duoc tinh la DD hoac business feature completion.
- Khong tao DD folder hoac coding health data/AI cho M20-M29 den khi module tuong ung co DD Approved va cac safety/privacy blocker duoc chot.
- Runtime/sandbox/RLS/API/audit evidence phai ghi worklog va cap nhat backlog truoc khi claim production acceptance.

### Cập nhật implementation evidence 2026-07-13 — entrypoint và role surface M05/M15

- M05 `AUTH_PROFILE_SYNC`: một Supabase session và một `main.dart`; auth event là nguồn phiên chung cho user/Admin.
- M15 `ADMIN_DASHBOARD`: quyền vẫn do `get_my_admin_session` quyết định; thêm `app_access_mode`/`can_use_user_app` để phân biệt Admin-only và dual-role.
- Existing active Admin được migration thành `both`; role revoke chuyển về user surface, không sign-out nhầm phiên người dùng.
- Source/unit/static contract đã bổ sung; Flutter analyze/test/build và Supabase sandbox smoke ba loại account còn là production evidence backlog.
