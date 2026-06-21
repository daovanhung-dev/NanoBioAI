# 00 - Đọc trước khi làm việc với Product Flow / Membership / Sale

**Module:** Product Flow, Membership, Quota, FamilyPlus, Sale / Referral  
**Nguồn BD:** `docs/BD/project_flow/BD_Product_Flow_Membership_Sale.md` (`BD-BIOAI-PRODUCT-FLOW-001`)  
**Trạng thái DD:** Draft  
**Cập nhật lần cuối:** 2026-06-21  

## 1. Quy tắc không được phá vỡ

1. Guest/V1 chỉ được dùng allowlist trong BD: onboarding cá nhân, sinh lịch trình AI lần đầu sau onboarding, tính toán sức khỏe cơ bản và thông báo theo lịch trình cá nhân.
2. Guest muốn tạo thêm lịch trình AI hoặc mở module ngoài V1 phải đi qua đăng nhập/đăng ký.
3. Free/V2 là trạng thái đã đăng nhập, đọc gói từ Supabase, có AI Chat 3 lượt/ngày và tạo lịch trình mới 3 lần/tháng.
4. Plus/V3 kế thừa Free và bỏ hai quota Free đã nêu; FamilyPlus/V3 kế thừa Plus và mở phạm vi gia đình.
5. Sale/referral là trục độc lập với membership tier; Sale không tự mở quyền sức khỏe, AI, gia đình hoặc paid feature.
6. Quyền cao cấp, quota, Sale status, quan hệ referral, payment success và commission phải đến từ Supabase/trusted backend, không từ local cache/client flag/UI state.
7. Không triển khai phần phụ thuộc Q-01..Q-10 như Ready khi chưa có quyết định Product Owner.

## 2. Thứ tự đọc theo loại task

| Công việc | Bắt buộc đọc |
|---|---|
| Guest onboarding / lịch trình đầu tiên | `04_FEATURE_GUEST_ONBOARDING_INITIAL_SCHEDULE.md`, `12_FEATURE_NOTIFICATION_SCHEDULE_REMINDERS.md`, `14_FLUTTER_LAYER_CONTRACTS.md` |
| Auth / membership gate | `05_FEATURE_AUTH_MEMBERSHIP_ACCESS_GATE.md`, `03_DATA_MODEL_SUPABASE_RLS_AND_MIGRATIONS.md`, `14_FLUTTER_LAYER_CONTRACTS.md` |
| Free quota AI Chat / lịch trình mới | `06_FEATURE_FREE_QUOTA_AI_CHAT_AND_SCHEDULE.md`, `03_DATA_MODEL_SUPABASE_RLS_AND_MIGRATIONS.md` |
| Health score | `07_FEATURE_HEALTH_SCORE_SCHEDULE_COMPLETION.md`, `15_TEST_ACCEPTANCE_AND_TRACEABILITY.md` |
| Plus planned | `08_FEATURE_PLUS_GOAL_ROADMAP_ADVANCED_TRACKING.md`, `05_FEATURE_AUTH_MEMBERSHIP_ACCESS_GATE.md` |
| FamilyPlus planned | `09_FEATURE_FAMILYPLUS_MEMBER_HEALTH_AND_SCHEDULE.md`, `03_DATA_MODEL_SUPABASE_RLS_AND_MIGRATIONS.md` |
| Sale / referral / commission | `10_FEATURE_SALE_REFERRAL_REGISTRATION.md`, `11_FEATURE_PAYMENT_COMMISSION_TWO_LEVEL.md`, `03_DATA_MODEL_SUPABASE_RLS_AND_MIGRATIONS.md` |
| Test / review | `15_TEST_ACCEPTANCE_AND_TRACEABILITY.md`, DD feature liên quan |
| Lập trình theo DD | `16_IMPLEMENTATION_ORDER.md`, DD feature liên quan, `.codex/playbooks/access_membership_referral.md` |

## 3. Checklist trước khi code

- [ ] Đã xác định task thuộc Guest/V1, Free/V2, Plus/V3, FamilyPlus/V3, Sale/referral hoặc nhiều trục kết hợp.
- [ ] Đã đọc `01_DOCUMENT_MAP.md` để biết DD chính và dependency.
- [ ] Đã kiểm tra DD có `Status: Ready for implementation` hay còn `Draft` do Q-01..Q-10.
- [ ] Đã xác định source quyền/quota là Supabase/trusted backend, không phải local cache/client.
- [ ] Đã xác định test IDs trong `15_TEST_ACCEPTANCE_AND_TRACEABILITY.md`.

## 4. Nguồn tham khảo cấu trúc DD

- Google Technical Writing - Documents: https://developers.google.com/tech-writing/one/documents
- Atlassian Software Design Document: https://www.atlassian.com/work-management/knowledge-sharing/documentation/software-design-document
- GitLab Architecture Design Documents: https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/
- Design Docs at Google: https://www.industrialempathy.com/posts/design-docs-at-google/

