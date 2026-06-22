Commit de xuat: docs(dd): cap nhat checklist tao DD

# Checklist tạo DD toàn dự án

## Product Flow / Membership / Sale

**BD nguồn:** `docs/BD/project_flow/BD_Product_Flow_Membership_Sale.md` (`BD-BIOAI-PRODUCT-FLOW-001`)  
**DD folder:** `docs/DD/product_flow/`  
**Checklist nguồn:** `docs/BD/project_flow/checklist_create_DD_product_flow_membership_sale.md`  
**Ngày cập nhật:** 2026-06-22

| # | DD | Status | BD source | Output path | Ngày hoàn thành | Ghi chú |
|---:|---|---|---|---|---|---|
| 1 | DD-PRODUCT-FLOW-READ-001 | Done | All | `docs/DD/product_flow/00_READ_FIRST.md` | 2026-06-21 | Entry point |
| 2 | DD-PRODUCT-FLOW-MAP-001 | Done | All BR/AC/UC | `docs/DD/product_flow/01_DOCUMENT_MAP.md` | 2026-06-21 | Mapping BD -> DD |
| 3 | DD-PRODUCT-FLOW-MOD-001 | Done | Sections 1..4, 8..9 | `docs/DD/product_flow/02_MODULE_OVERVIEW.md` | 2026-06-21 | Module overview |
| 4 | DD-PRODUCT-FLOW-DB-001 | Done | Section 8, Supabase docs | `docs/DD/product_flow/03_DATA_MODEL_SUPABASE_RLS_AND_MIGRATIONS.md` | 2026-06-21 | Draft due Q-01/Q-02/Q-04/Q-06/Q-07/Q-09/Q-10 |
| 5 | DD-PRODUCT-FLOW-FR-001 | Done | BR-01..03, UC-01..04, AC-01..03 | `docs/DD/product_flow/04_FEATURE_GUEST_ONBOARDING_INITIAL_SCHEDULE.md` | 2026-06-21 | Draft due Q-01/Q-02 |
| 6 | DD-PRODUCT-FLOW-FR-002 | Done | BR-04, UC-05 | `docs/DD/product_flow/05_FEATURE_AUTH_MEMBERSHIP_ACCESS_GATE.md` | 2026-06-21 | Draft due Q-06 |
| 7 | DD-PRODUCT-FLOW-FR-003 | Done | BR-05, UC-06..07, AC-04..05 | `docs/DD/product_flow/06_FEATURE_FREE_QUOTA_AI_CHAT_AND_SCHEDULE.md` | 2026-06-21 | Draft due Q-03/Q-04 |
| 8 | DD-PRODUCT-FLOW-FR-004 | Done | BR-08, UC-08 | `docs/DD/product_flow/07_FEATURE_HEALTH_SCORE_SCHEDULE_COMPLETION.md` | 2026-06-21 | Draft due Q-05 |
| 9 | DD-PRODUCT-FLOW-FR-005 | Done | BR-06, UC-09..10, AC-06 | `docs/DD/product_flow/08_FEATURE_PLUS_GOAL_ROADMAP_ADVANCED_TRACKING.md` | 2026-06-21 | Draft due Q-05/Q-06 |
| 10 | DD-PRODUCT-FLOW-FR-006 | Done | BR-07, UC-11, AC-07 | `docs/DD/product_flow/09_FEATURE_FAMILYPLUS_MEMBER_HEALTH_AND_SCHEDULE.md` | 2026-06-21 | Draft due Q-06/Q-07 |
| 11 | DD-PRODUCT-FLOW-FR-007 | Done | Section 7.1..7.3, UC-12..13 | `docs/DD/product_flow/10_FEATURE_SALE_REFERRAL_REGISTRATION.md` | 2026-06-21 | Draft due Q-08/Q-09 |
| 12 | DD-PRODUCT-FLOW-FR-008 | Done | Section 7.4..7.6, UC-14..15, AC-08..11 | `docs/DD/product_flow/11_FEATURE_PAYMENT_COMMISSION_TWO_LEVEL.md` | 2026-06-21 | Draft due Q-09/Q-10 |
| 13 | DD-PRODUCT-FLOW-FR-009 | Done | UC-04, Section 9.3 | `docs/DD/product_flow/12_FEATURE_NOTIFICATION_SCHEDULE_REMINDERS.md` | 2026-06-21 | Draft due Q-07 for family notifications |
| 14 | DD-PRODUCT-FLOW-CROSS-001 | Done | Section 9, Q-01..Q-10 | `docs/DD/product_flow/13_ERROR_HANDLING_SECURITY_AND_PRIVACY.md` | 2026-06-21 | Cross-cutting |
| 15 | DD-PRODUCT-FLOW-CTR-001 | Done | Section 9.1 | `docs/DD/product_flow/14_FLUTTER_LAYER_CONTRACTS.md` | 2026-06-21 | Layer contracts |
| 16 | DD-PRODUCT-FLOW-TEST-001 | Done | Section 10, all AC | `docs/DD/product_flow/15_TEST_ACCEPTANCE_AND_TRACEABILITY.md` | 2026-06-21 | Test matrix |
| 17 | DD-PRODUCT-FLOW-PLAN-001 | Done | All | `docs/DD/product_flow/16_IMPLEMENTATION_ORDER.md` | 2026-06-21 | Implementation order |

## Ghi chú

- `Done` trong checklist này nghĩa là DD đã được tạo, không có nghĩa DD đã Ready for implementation.
- Các DD còn phụ thuộc Q-01..Q-10 giữ `Status: Draft` và phải được PO/Tech Lead chốt trước khi coding.

## Chức năng chưa hoàn thành theo DD

> Cập nhật 2026-06-22: các mục dưới đây chưa được xác nhận hoàn thành trong DD vì còn `Status: Draft`, còn open decision, thiếu dependency, hoặc test matrix vẫn ở `Draft`.

| Nhóm chức năng | DD liên quan | Trạng thái đơn giản | Ghi chú |
|---|---|---|---|
| Supabase foundation, RLS, migration cho profile, health subject, membership, quota, FamilyPlus, Sale/referral, payment, commission | 03 | Chưa hoàn thành | Cần review sandbox/staging; còn Q-01/Q-02/Q-04/Q-06/Q-07/Q-09/Q-10; dependency `docs/DD/authentication/*` đang không có trong working tree hiện tại. |
| Guest onboarding, sinh lịch trình AI lần đầu, chặn tạo lại và chặn module ngoài V1 | 04, 12 | Chưa xác nhận hoàn thành | Còn Q-01/Q-02; test TC-PF-01..04 và TC-PF-29..32 vẫn `Draft`. |
| Auth membership access gate, effective access, Sale axis độc lập | 05 | Chưa hoàn thành | Còn Q-06; phụ thuộc Auth DD; test TC-PF-05..08 vẫn `Draft`. |
| Free quota cho AI Chat 3 lượt/ngày và tạo lịch trình 3 lần/tháng | 06 | Chưa hoàn thành | Còn Q-03/Q-04 và cần trusted quota layer/RPC; test TC-PF-09..12 vẫn `Draft`. |
| Health score theo lịch sử hoàn thành lịch trình | 07 | Chưa hoàn thành | Còn Q-05 về công thức điểm; test TC-PF-13..15 vẫn `Draft`. |
| Plus goal roadmap và advanced tracking | 08 | Chưa hoàn thành | Chỉ là planned capability; cần DD chi tiết `Ready`; còn Q-05/Q-06. |
| FamilyPlus quản lý thành viên, health subject và lịch trình theo từng member | 09, 12 | Chưa hoàn thành | Còn Q-06/Q-07 về lifecycle, giới hạn member, quyền và consent; test TC-PF-18..20 vẫn `Draft`. |
| Sale/referral registration, referral code, quan hệ giới thiệu | 10 | Chưa hoàn thành | Còn Q-08/Q-09 về điều kiện Sale, duy trì/khóa Sale và anti-fraud; test TC-PF-21..23 vẫn `Draft`. |
| Payment commission hai tầng và Sale dashboard/history | 11 | Chưa hoàn thành | Còn Q-09/Q-10 về refund/chargeback, đối soát, hủy hoa hồng, payout; test TC-PF-24..28 vẫn `Draft`. |
| Error/security/privacy và Flutter layer contracts | 13, 14 | Chưa hoàn thành | Backend/quota/Sale contracts chưa approved; test TC-PF-33..38 vẫn `Draft`. |
| Test acceptance toàn bộ product flow | 15 | Chưa hoàn thành | 38/38 test case trong DD đang `Draft`; security checklist chưa tick. |
| Các phase triển khai B..G | 16 | Chưa hoàn thành | Phase B Supabase, C Guest hardening, D Auth/Free quota, E Health score, F Plus/FamilyPlus, G Sale/payment đều chưa có gate pass trong DD. |
