Commit de xuat: docs(dd): tao checklist DD product flow membership sale

# Checklist tạo DD - Product Flow / Membership / Sale

**BD nguồn:** `BD-BIOAI-PRODUCT-FLOW-001`  
**File BD:** `docs/BD/project_flow/BD_Product_Flow_Membership_Sale.md`  
**DD folder:** `docs/DD/product_flow/`  
**Ngày tạo checklist:** 2026-06-21  

## 1. Checklist DD

| # | DD | BD mapping | Output | Status |
|---:|---|---|---|---|
| 1 | Read first | All | `docs/DD/product_flow/00_READ_FIRST.md` | Done |
| 2 | Document map | All BR/AC/UC | `docs/DD/product_flow/01_DOCUMENT_MAP.md` | Done |
| 3 | Module overview | Sections 1..4, 8..9 | `docs/DD/product_flow/02_MODULE_OVERVIEW.md` | Done |
| 4 | Data model / Supabase / RLS | Section 8, Section 9, Supabase docs | `docs/DD/product_flow/03_DATA_MODEL_SUPABASE_RLS_AND_MIGRATIONS.md` | Done |
| 5 | Guest onboarding initial schedule | BR-01..03, UC-01..04, AC-01..03 | `docs/DD/product_flow/04_FEATURE_GUEST_ONBOARDING_INITIAL_SCHEDULE.md` | Done |
| 6 | Auth membership access gate | BR-04, UC-05 | `docs/DD/product_flow/05_FEATURE_AUTH_MEMBERSHIP_ACCESS_GATE.md` | Done |
| 7 | Free quota AI chat/schedule | BR-05, UC-06..07, AC-04..05 | `docs/DD/product_flow/06_FEATURE_FREE_QUOTA_AI_CHAT_AND_SCHEDULE.md` | Done |
| 8 | Health score completion | BR-08, UC-08 | `docs/DD/product_flow/07_FEATURE_HEALTH_SCORE_SCHEDULE_COMPLETION.md` | Done |
| 9 | Plus planned | BR-06, UC-09..10, AC-06 | `docs/DD/product_flow/08_FEATURE_PLUS_GOAL_ROADMAP_ADVANCED_TRACKING.md` | Done |
| 10 | FamilyPlus planned | BR-07, UC-11, AC-07 | `docs/DD/product_flow/09_FEATURE_FAMILYPLUS_MEMBER_HEALTH_AND_SCHEDULE.md` | Done |
| 11 | Sale referral registration | Section 7.1..7.3, UC-12..13 | `docs/DD/product_flow/10_FEATURE_SALE_REFERRAL_REGISTRATION.md` | Done |
| 12 | Payment commission two-level | Section 7.4..7.6, UC-14..15, AC-08..11 | `docs/DD/product_flow/11_FEATURE_PAYMENT_COMMISSION_TWO_LEVEL.md` | Done |
| 13 | Notification reminders | UC-04, Section 9.3 | `docs/DD/product_flow/12_FEATURE_NOTIFICATION_SCHEDULE_REMINDERS.md` | Done |
| 14 | Error/security/privacy | Section 9, Q-01..Q-10 | `docs/DD/product_flow/13_ERROR_HANDLING_SECURITY_AND_PRIVACY.md` | Done |
| 15 | Flutter layer contracts | Section 9.1 | `docs/DD/product_flow/14_FLUTTER_LAYER_CONTRACTS.md` | Done |
| 16 | Test acceptance traceability | Section 10, all AC | `docs/DD/product_flow/15_TEST_ACCEPTANCE_AND_TRACEABILITY.md` | Done |
| 17 | Implementation order | All | `docs/DD/product_flow/16_IMPLEMENTATION_ORDER.md` | Done |

## 2. Open decisions phải giữ Draft

| ID | DD impacted | Status |
|---|---|---|
| Q-01 | 04 | Open |
| Q-02 | 04, 03 | Open |
| Q-03 | 06 | Open |
| Q-04 | 06, 03 | Open |
| Q-05 | 07, 08 | Open |
| Q-06 | 05, 08, 09, 03 | Open |
| Q-07 | 09, 12, 03, 13 | Open |
| Q-08 | 10 | Open |
| Q-09 | 10, 11 | Open |
| Q-10 | 11, 03, 13 | Open |

## 3. Definition of Done cho bước tạo DD

- [x] Có folder module `docs/DD/product_flow/`.
- [x] Có đủ 17 DD theo plan.
- [x] Mỗi DD có BD source, status, dependencies, scope/non-scope hoặc equivalent, layer/data/security/test/open decisions.
- [x] Checklist global `docs/checklist/checklist_create_DD.md` được cập nhật.
- [x] `.codex` có playbook/rule phục vụ phiên sau.
- [x] Worklog được tạo cho phiên docs.

