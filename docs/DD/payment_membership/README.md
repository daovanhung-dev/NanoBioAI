# DD — Thanh toán, xác minh và quyền gói

| Attribute | Value |
|---|---|
| Module Code | PAYMENT_MEMBERSHIP |
| BD Module | M13 |
| Version | v1.4 |
| Status | Approved - DD docs complete; sandbox/UAT acceptance pending |
| Owner | Product Owner / Tech Lead |
| Created Date | 2026-06-28 |
| Last Updated | 2026-08-12 |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), M13 decisions and approved VietQR hardening delta 2026-08-12 |

## Purpose

Ghi nhận giao dịch mua/gia hạn Plus hoặc FamilyPlus bằng VietQR, xác minh thủ công qua Finance/Super Admin và chỉ kích hoạt quyền sau payment `succeeded`. “VIP” chỉ là cách gọi chung trong trao đổi sản phẩm, không phải một plan code mới.

## Documents in This Module

- [Overall](./Overall.md)
- [Feature List](./List_Features.md)
- [Function List](./Function_List.md)
- [Views](./Views.md)
- [Import and File Mapping](./Import_File.md)
- [Diagrams](./diagrams/README.md)
- [Assets](./assets/README.md)
- [Change History](./history/CHANGELOG.md)

## Traceability Summary

- `PAYMENT_MEMBERSHIP-F01`: CTA nâng cấp, tạo/khôi phục/hủy/xác nhận yêu cầu VietQR của Member.
- `PAYMENT_MEMBERSHIP-F02`: Finance/Super Admin xem hàng chờ, đối chiếu VCB, duyệt/từ chối và audit.

## Canonical VietQR Contract

- Plan mua: `plus` hoặc `family_plus`; route `/v2/payments?plan=...`; giá trị khác fallback `plus` ở UI.
- Giá và thông tin nhận tiền do Supabase quyết định; Flutter không truyền số tiền/tài khoản nhận/reference.
- Tài khoản nhận: Vietcombank, BIN `970436`, số tài khoản `1026806174`, chủ tài khoản `LE PHU THACH` / hiển thị `Lê Phú Thạch`.
- Mã đối soát duy nhất: `NB` + 12 ký tự hex in hoa, regex `^NB[0-9A-F]{12}$`.
- `transfer_memo` phải bằng đúng `transfer_reference`; họ tên/gói/chu kỳ chỉ là metadata/display, không nằm trong nội dung chuyển khoản.
- Một user chỉ có tối đa một request mở (`awaiting_transfer` hoặc `pending_review`).
- Member chỉ hủy được request của chính mình khi `awaiting_transfer`; hủy lặp lại trên `canceled` là idempotent.
- “Đã chuyển khoản” chỉ chuyển `awaiting_transfer -> pending_review`; không cấp quyền.
- Chỉ `finance_admin` và `super_admin` được xem alert/queue và review payment. Support/Content/Operations bị chặn cả backend lẫn UI.
- Duyệt bắt buộc reason + xác nhận đã đối chiếu mã NB, số tiền và nội dung trong ứng dụng VCB.
- Chỉ approve tạo/gia hạn/chuyển subscription; reject không tạo quyền.
- Same-plan renewal nối từ `ends_at` còn hiệu lực. Plus ↔ FamilyPlus chuyển ngay tại thời điểm duyệt và audit liên kết subscription bị thay thế.
- Chu kỳ tháng/năm là một tháng/năm lịch theo `Asia/Ho_Chi_Minh`.
- Active paid subscription cũ thiếu `ends_at` phải block approval để data repair có kiểm soát; không tự đoán hạn.

## Dependent Modules

- MEMBERSHIP_QUOTA: trusted effective access và quota.
- AUTH_PROFILE_SYNC / cloud sync: pull `users.subscription_tier` về SQLite read-model sau approve.
- DASHBOARD_SCHEDULE: refresh nhãn gói từ SQLite sau trusted cloud pull.
- FAMILYPLUS / Advanced Tracking / paid feature gates: CTA dùng shared upgrade route.
- REFERRAL_DIRECT + SALE_POINTS: commission/points chỉ sau payment thành công theo contract riêng.
- ADMIN_OPS / AUDIT_SECURITY: reviewer permission, reason/idempotency/audit.

## Answered Questions

| ID | Decision | Status |
|---|---|---|
| Q-03 | Commission tính từ giá niêm yết theo contract Sale. | Accepted - 2026-06-30 |
| Q-04 | Plus/FamilyPlus có tháng/năm; gia hạn sớm nối từ hạn hiện tại, trễ bắt đầu từ lúc duyệt. | Accepted - 2026-06-30; hardened 2026-08-12 |
| Q-05 | Refund/cancel sau purchase theo policy 24h và reversal ledger; khác với user-cancel request trước chuyển khoản. | Accepted - 2026-06-30 |
| Q-11 | FamilyPlus commission chỉ tính phần owner theo contract Sale. | Accepted - 2026-06-30 |
| Q-17 | Không webhook/auto-approve; payment phải review thủ công. | Accepted - 2026-06-30 |
| Q-18 | VietQR VCB manual review; mã NB là memo duy nhất; Finance/Super Admin duyệt sau đối chiếu thực tế. | Accepted - 2026-07-31; hardened 2026-08-12 |

## Validation Notes

- Source/runtime + SQL contract hardening có test nguồn và rollback-only SQL smoke trong patch này.
- Supabase sandbox/RLS/two-session concurrency và quét QR/đối soát bằng ứng dụng VCB vẫn là acceptance bắt buộc trước production.
- Không có webhook, API ngân hàng, upload biên lai hoặc tự động xác nhận số dư trong phạm vi M13 này.
