# 01 - Bản đồ DD Product Flow / Membership / Sale

**BD nguồn:** `BD-BIOAI-PRODUCT-FLOW-001`  
**Status:** Draft  
**Dependencies:** `docs/supabase/*`, `docs/DD/authentication/*`, `.codex/playbooks/access_membership_referral.md`  

## 1. Cấu trúc thư mục

```text
docs/DD/product_flow/
├── 00_READ_FIRST.md
├── 01_DOCUMENT_MAP.md
├── 02_MODULE_OVERVIEW.md
├── 03_DATA_MODEL_SUPABASE_RLS_AND_MIGRATIONS.md
├── 04_FEATURE_GUEST_ONBOARDING_INITIAL_SCHEDULE.md
├── 05_FEATURE_AUTH_MEMBERSHIP_ACCESS_GATE.md
├── 06_FEATURE_FREE_QUOTA_AI_CHAT_AND_SCHEDULE.md
├── 07_FEATURE_HEALTH_SCORE_SCHEDULE_COMPLETION.md
├── 08_FEATURE_PLUS_GOAL_ROADMAP_ADVANCED_TRACKING.md
├── 09_FEATURE_FAMILYPLUS_MEMBER_HEALTH_AND_SCHEDULE.md
├── 10_FEATURE_SALE_REFERRAL_REGISTRATION.md
├── 11_FEATURE_PAYMENT_COMMISSION_TWO_LEVEL.md
├── 12_FEATURE_NOTIFICATION_SCHEDULE_REMINDERS.md
├── 13_ERROR_HANDLING_SECURITY_AND_PRIVACY.md
├── 14_FLUTTER_LAYER_CONTRACTS.md
├── 15_TEST_ACCEPTANCE_AND_TRACEABILITY.md
└── 16_IMPLEMENTATION_ORDER.md
```

## 2. Mapping từ BD sang DD

| BD requirement / section | DD chính | DD phụ thuộc |
|---|---|---|
| BR-01, BR-02, BR-03, UC-01, UC-02, AC-01, AC-02, AC-03 | `04_FEATURE_GUEST_ONBOARDING_INITIAL_SCHEDULE.md` | 03, 12, 13, 14, 15 |
| UC-03 basic health calculation | `04_FEATURE_GUEST_ONBOARDING_INITIAL_SCHEDULE.md` | 07 nếu tính điểm/dashboard |
| UC-04 notification theo lịch trình | `12_FEATURE_NOTIFICATION_SCHEDULE_REMINDERS.md` | 04, 13, 14, 15 |
| BR-04, UC-05 | `05_FEATURE_AUTH_MEMBERSHIP_ACCESS_GATE.md` | 03, 13, 14, DD authentication |
| BR-05, UC-06, UC-07, AC-04, AC-05 | `06_FEATURE_FREE_QUOTA_AI_CHAT_AND_SCHEDULE.md` | 03, 05, 13, 14, 15 |
| BR-08, UC-08 | `07_FEATURE_HEALTH_SCORE_SCHEDULE_COMPLETION.md` | 03, 04, 06, 14, 15 |
| BR-06, UC-09, UC-10, AC-06 | `08_FEATURE_PLUS_GOAL_ROADMAP_ADVANCED_TRACKING.md` | 03, 05, 06, 07, 14 |
| BR-07, UC-11, AC-07 | `09_FEATURE_FAMILYPLUS_MEMBER_HEALTH_AND_SCHEDULE.md` | 03, 05, 08, 13, 14 |
| Section 7.1..7.3, UC-12, UC-13 | `10_FEATURE_SALE_REFERRAL_REGISTRATION.md` | 03, 05, 13, 14 |
| Section 7.4..7.6, UC-14, UC-15, AC-08..AC-11 | `11_FEATURE_PAYMENT_COMMISSION_TWO_LEVEL.md` | 03, 10, 13, 15 |
| Section 8 data model concept | `03_DATA_MODEL_SUPABASE_RLS_AND_MIGRATIONS.md` | Supabase draft docs |
| Section 9 access/quota/notification rules | 05, 06, 12 | 13, 14, 15 |
| Section 10 acceptance criteria | `15_TEST_ACCEPTANCE_AND_TRACEABILITY.md` | All DD features |
| Section 11 `.codex` update | `.codex/playbooks/dd_creation.md` | `.codex/README.md`, `.codex/PROJECT_MAP.md` |
| Q-01..Q-10 | Open decisions in impacted DDs | Must not be assumed |

## 3. Quy ước tên tài liệu

- `DD-PRODUCT-FLOW-MOD-*`: thiết kế cấp module/product flow.
- `DD-PRODUCT-FLOW-DB-*`: thiết kế database, Supabase, RLS, migration.
- `DD-PRODUCT-FLOW-FR-*`: thiết kế feature theo BD requirement.
- `DD-PRODUCT-FLOW-CTR-*`: hợp đồng Flutter layer/route/controller.
- `DD-PRODUCT-FLOW-TEST-*`: test, acceptance và traceability.
- `DD-PRODUCT-FLOW-PLAN-*`: thứ tự triển khai.

## 4. Trạng thái DD

- `Draft`: đã tách scope và rule nhưng còn phụ thuộc Q-01..Q-10 hoặc DD/backend chi tiết.
- `Review`: đủ dữ liệu để reviewer/PO xác nhận.
- `Ready for implementation`: không còn quyết định nghiệp vụ/technical blocker trong phạm vi file.
- `Implemented`: đã có code/test/worklog trace đủ.

