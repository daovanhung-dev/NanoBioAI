# List Features — AUTH_PROFILE_SYNC / Xác thực, hồ sơ và đồng bộ Guest

## 0. Document Information

| Field | Value |
|---|---|
| Module | AUTH_PROFILE_SYNC |
| Overall | [Overall.md](Overall.md) |
| Version | v1.0 |
| Last Updated | 2026-06-28 |
| Source | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 6/M05, 13, Appendix A UC-05 |

## 1. Feature Inventory

| ID | Feature | Goal | Actor | Trigger | Priority | Source | Functions | Views | Status |
|---|---|---|---|---|---|---|---|---|---|
| AUTH_PROFILE_SYNC-F01 | Đăng ký/đăng nhập và dựng quyền | Member có session và quyền hiệu lực đúng. | Guest, Member | Submit login/sign-up | P0 | BD M05 luồng đăng ký/đăng nhập | AUTH_PROFILE_SYNC-FN01 | AUTH_PROFILE_SYNC-V01 | Draft |
| AUTH_PROFILE_SYNC-F02 | Đồng bộ dữ liệu Guest | Liên kết dữ liệu local với tài khoản mà không mất lịch trình/hồ sơ. | Guest, Member | Login after guest usage | P0 | BD M05 Guest -> Member | AUTH_PROFILE_SYNC-FN02 | AUTH_PROFILE_SYNC-V02 | Draft |

## 2. Dependencies Between Features

| Source Feature | Relationship | Target Feature | Data / State Passed | Condition |
|---|---|---|---|---|
| AUTH_PROFILE_SYNC-F01 | prerequisite / trigger | Next feature in this module | Module state and actor context | Previous feature succeeds and business rules pass |
| Cross-module | dependency | Related module DD | Entitlement, ownership, audit, or event state | Dependency module is available and not blocked by open questions |

---

<a id="auth_profile_sync-f01"></a>
# AUTH_PROFILE_SYNC-F01 — Đăng ký/đăng nhập và dựng quyền

## A. Mục đích và phạm vi

| Hạng mục | Nội dung |
|---|---|
| Mục tiêu nghiệp vụ | Member có session và quyền hiệu lực đúng. |
| Actor chính | Guest, Member |
| Actor phụ / hệ thống | Supabase Auth, entitlement service |
| Trigger | Submit login/sign-up |
| Phạm vi | Authenticate, load package, Sale/Admin axis. |
| Không thuộc feature | Payment verification. |
| Requirement nguồn | BD M05 luồng đăng ký/đăng nhập |
| Rule áp dụng | AUTH_PROFILE_SYNC-BR01 |
| View liên quan | AUTH_PROFILE_SYNC-V01 |
| Function liên quan | AUTH_PROFILE_SYNC-FN01 |

## B. Điều kiện

| Loại | Nội dung |
|---|---|
| Tiền điều kiện | Actor có trạng thái và quyền phù hợp theo BD sections 3, 5 và module source BD sections 6/M05, 13, Appendix A UC-05. |
| Hậu điều kiện thành công | Dữ liệu/trạng thái của Xác thực, hồ sơ và đồng bộ Guest được cập nhật và có thể truy vết tới BD M05 luồng đăng ký/đăng nhập. |
| Hậu điều kiện thất bại | Không ghi dữ liệu một phần; trả thông báo nghiệp vụ an toàn và ghi audit khi tác động quyền, tiền, điểm, dữ liệu gia đình hoặc cấu hình. |
| Idempotency | Mọi thao tác tạo/sửa trạng thái quan trọng dùng request/correlation id hoặc khóa nghiệp vụ theo BD sections 14.4 và 15. |

## C. Luồng chính

1. Guest, Member mở AUTH_PROFILE_SYNC-V01 hoặc entry point liên quan.
2. Hệ thống xác thực trạng thái đăng nhập/gói/vai trò theo quyền hiệu lực.
3. Hệ thống tải dữ liệu nguồn của module: @{Id=app_user; Name=App User; Purpose=Hồ sơ app liên kết auth; Attributes=auth_user_id, account status, package status, sale status; Relationships=Owns profile and entitlements}, @{Id=guest_sync; Name=Guest Sync Snapshot; Purpose=Dữ liệu chuyển local-cloud; Attributes=local key, sync status, conflict policy; Relationships=Links Guest Profile to App User}.
4. Actor thực hiện hành động: Submit login/sign-up.
5. AUTH_PROFILE_SYNC-FN01 kiểm tra AUTH_PROFILE_SYNC-BR01 và các rule bảo mật/audit liên quan.
6. Hệ thống lưu hoặc trả kết quả theo trạng thái hợp lệ.
7. UI/API hiển thị kết quả, không lộ dữ liệu kỹ thuật hoặc dữ liệu nhạy cảm.

## D. Luồng thay thế và lỗi

| Mã luồng | Điều kiện | Hệ thống xử lý | Dữ liệu thay đổi | UI/API trả về | Test bắt buộc |
|---|---|---|---|---|---|
| AUTH_PROFILE_SYNC-F01-ALT01 | Dữ liệu chưa đủ hoặc chưa đến trạng thái cho phép | Giữ trạng thái hiện tại và hướng dẫn bước cần làm tiếp | Không ghi thay đổi chính | Thông báo nghiệp vụ an toàn | AUTH_PROFILE_SYNC-TC01 |
| AUTH_PROFILE_SYNC-F01-ERR01 | Không đủ quyền hoặc sai phạm vi dữ liệu | Chặn ở route/use-case/API và ghi audit nếu là quyền nhạy cảm | Không ghi | Permission denied theo Nabitone | AUTH_PROFILE_SYNC-TC01 |
| AUTH_PROFILE_SYNC-F01-ERR02 | Dependency lỗi hoặc thao tác bị retry | Xử lý idempotent, không nhân đôi side effect | Không ghi trùng | Cho retry hoặc báo đang xử lý | AUTH_PROFILE_SYNC-TC01 |

## E. Quy tắc nghiệp vụ áp dụng

| Rule ID | Cách feature áp dụng | Bước kiểm tra | Message/mã lỗi |
|---|---|---:|---|
| AUTH_PROFILE_SYNC-BR01 | Áp dụng rule module đã định nghĩa trong Overall.md, không định nghĩa lại ở UI. | 5 | BUSINESS_RULE_BLOCKED |

## F. Dữ liệu, API và event

| Loại | ID / tên | Vai trò trong feature | Đọc / Ghi | Ghi chú |
|---|---|---|---|---|
| Entity | AUTH_PROFILE_SYNC-E-main | Dữ liệu nghiệp vụ chính của Xác thực, hồ sơ và đồng bộ Guest | Read/Write theo feature | Planned logical entity, schema vật lý cần DD/Supabase riêng khi có coding. |
| API/Event | AUTH_PROFILE_SYNC-API01 | Contract dự kiến cho AUTH_PROFILE_SYNC-FN01 | Expose/Consume | Request/response phải được chốt trước implementation. |

## G. Tiêu chí chấp nhận

- [ ] Với source BD M05 luồng đăng ký/đăng nhập, feature tạo đúng outcome: Member có session và quyền hiệu lực đúng..
- [ ] Khi quyền không hợp lệ, hệ thống chặn ở UI/route/use-case/API, không chỉ ẩn nút.
- [ ] Khi retry hoặc double click, không tạo dữ liệu/điểm/quyền trùng.
- [ ] AUTH_PROFILE_SYNC-V01 có đủ Loading, Empty, Success, Business Error, System Error và Permission Denied.
---

<a id="auth_profile_sync-f02"></a>
# AUTH_PROFILE_SYNC-F02 — Đồng bộ dữ liệu Guest

## A. Mục đích và phạm vi

| Hạng mục | Nội dung |
|---|---|
| Mục tiêu nghiệp vụ | Liên kết dữ liệu local với tài khoản mà không mất lịch trình/hồ sơ. |
| Actor chính | Guest, Member |
| Actor phụ / hệ thống | Local storage, backend |
| Trigger | Login after guest usage |
| Phạm vi | Merge profile, plan, schedule state. |
| Không thuộc feature | Manual data repair without policy. |
| Requirement nguồn | BD M05 Guest -> Member |
| Rule áp dụng | AUTH_PROFILE_SYNC-BR02 |
| View liên quan | AUTH_PROFILE_SYNC-V02 |
| Function liên quan | AUTH_PROFILE_SYNC-FN02 |

## B. Điều kiện

| Loại | Nội dung |
|---|---|
| Tiền điều kiện | Actor có trạng thái và quyền phù hợp theo BD sections 3, 5 và module source BD sections 6/M05, 13, Appendix A UC-05. |
| Hậu điều kiện thành công | Dữ liệu/trạng thái của Xác thực, hồ sơ và đồng bộ Guest được cập nhật và có thể truy vết tới BD M05 Guest -> Member. |
| Hậu điều kiện thất bại | Không ghi dữ liệu một phần; trả thông báo nghiệp vụ an toàn và ghi audit khi tác động quyền, tiền, điểm, dữ liệu gia đình hoặc cấu hình. |
| Idempotency | Mọi thao tác tạo/sửa trạng thái quan trọng dùng request/correlation id hoặc khóa nghiệp vụ theo BD sections 14.4 và 15. |

## C. Luồng chính

1. Guest, Member mở AUTH_PROFILE_SYNC-V02 hoặc entry point liên quan.
2. Hệ thống xác thực trạng thái đăng nhập/gói/vai trò theo quyền hiệu lực.
3. Hệ thống tải dữ liệu nguồn của module: @{Id=app_user; Name=App User; Purpose=Hồ sơ app liên kết auth; Attributes=auth_user_id, account status, package status, sale status; Relationships=Owns profile and entitlements}, @{Id=guest_sync; Name=Guest Sync Snapshot; Purpose=Dữ liệu chuyển local-cloud; Attributes=local key, sync status, conflict policy; Relationships=Links Guest Profile to App User}.
4. Actor thực hiện hành động: Login after guest usage.
5. AUTH_PROFILE_SYNC-FN02 kiểm tra AUTH_PROFILE_SYNC-BR02 và các rule bảo mật/audit liên quan.
6. Hệ thống lưu hoặc trả kết quả theo trạng thái hợp lệ.
7. UI/API hiển thị kết quả, không lộ dữ liệu kỹ thuật hoặc dữ liệu nhạy cảm.

## D. Luồng thay thế và lỗi

| Mã luồng | Điều kiện | Hệ thống xử lý | Dữ liệu thay đổi | UI/API trả về | Test bắt buộc |
|---|---|---|---|---|---|
| AUTH_PROFILE_SYNC-F02-ALT01 | Dữ liệu chưa đủ hoặc chưa đến trạng thái cho phép | Giữ trạng thái hiện tại và hướng dẫn bước cần làm tiếp | Không ghi thay đổi chính | Thông báo nghiệp vụ an toàn | AUTH_PROFILE_SYNC-TC02 |
| AUTH_PROFILE_SYNC-F02-ERR01 | Không đủ quyền hoặc sai phạm vi dữ liệu | Chặn ở route/use-case/API và ghi audit nếu là quyền nhạy cảm | Không ghi | Permission denied theo Nabitone | AUTH_PROFILE_SYNC-TC02 |
| AUTH_PROFILE_SYNC-F02-ERR02 | Dependency lỗi hoặc thao tác bị retry | Xử lý idempotent, không nhân đôi side effect | Không ghi trùng | Cho retry hoặc báo đang xử lý | AUTH_PROFILE_SYNC-TC02 |

## E. Quy tắc nghiệp vụ áp dụng

| Rule ID | Cách feature áp dụng | Bước kiểm tra | Message/mã lỗi |
|---|---|---:|---|
| AUTH_PROFILE_SYNC-BR02 | Áp dụng rule module đã định nghĩa trong Overall.md, không định nghĩa lại ở UI. | 5 | BUSINESS_RULE_BLOCKED |

## F. Dữ liệu, API và event

| Loại | ID / tên | Vai trò trong feature | Đọc / Ghi | Ghi chú |
|---|---|---|---|---|
| Entity | AUTH_PROFILE_SYNC-E-main | Dữ liệu nghiệp vụ chính của Xác thực, hồ sơ và đồng bộ Guest | Read/Write theo feature | Planned logical entity, schema vật lý cần DD/Supabase riêng khi có coding. |
| API/Event | AUTH_PROFILE_SYNC-API02 | Contract dự kiến cho AUTH_PROFILE_SYNC-FN02 | Expose/Consume | Request/response phải được chốt trước implementation. |

## G. Tiêu chí chấp nhận

- [ ] Với source BD M05 Guest -> Member, feature tạo đúng outcome: Liên kết dữ liệu local với tài khoản mà không mất lịch trình/hồ sơ..
- [ ] Khi quyền không hợp lệ, hệ thống chặn ở UI/route/use-case/API, không chỉ ẩn nút.
- [ ] Khi retry hoặc double click, không tạo dữ liệu/điểm/quyền trùng.
- [ ] AUTH_PROFILE_SYNC-V02 có đủ Loading, Empty, Success, Business Error, System Error và Permission Denied.
