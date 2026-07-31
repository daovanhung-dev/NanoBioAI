# Views — PAYMENT_MEMBERSHIP / Thanh toán, xác minh và quyền gói

## 0. View Inventory

| ID | View Name | Route / Entry Point | Actor | Feature | Type | Data Source | Status | Mockup |
|---|---|---|---|---|---|---|---|---|
| PAYMENT_MEMBERSHIP-V01 | Payment checkout | /v2/payments | Member | PAYMENT_MEMBERSHIP-F01 | Page | create/get/confirm membership payment RPC | Implemented - VietQR manual review | assets/README.md |
| PAYMENT_MEMBERSHIP-V02 | Payment approval queue | /admin/payments | Admin with payments.write | PAYMENT_MEMBERSHIP-F02 | Admin page + shell banner | Admin payment RPC | Implemented - VietQR manual review | assets/README.md |

## 1. Navigation Map

| Source | Action | Destination | Condition |
|---|---|---|---|
| Module entry | Actor selects feature action | Feature view | Actor has permission and dependency data can load |
| Feature view | Submit/confirm | Result state or next feature | PAYMENT_MEMBERSHIP-FNxx succeeds |
| Any view | Permission/data error | Safe error state | UI, route, use-case, or API blocks access |

---

<a id="payment_membership-v01"></a>
# PAYMENT_MEMBERSHIP-V01 — Payment checkout

## A. Thông tin cơ bản

| Trường | Nội dung |
|---|---|
| Feature liên quan | PAYMENT_MEMBERSHIP-F01 |
| Route / entry point | /v2/payments |
| Loại view | Page / Screen / Widget / Admin view depending on platform surface |
| Actor được phép | Member |
| Điều kiện truy cập | Theo quyền hiệu lực trong BD sections 3 và 5. |
| Hành vi khi không đủ quyền | Chặn ở route/use-case/API; UI chỉ hiển thị hướng dẫn an toàn. |
| Responsive | Mobile first for app surfaces; desktop/tablet for Admin surfaces. |
| Mockup / prototype | Optional future asset: BD v2.0 has no required mockup; view state/action contract is complete in this DD |

## B. Layout và thành phần giao diện

| Component ID | Khu vực | Loại | Nội dung / label | Hiển thị khi | Dữ liệu nguồn | Validation / rule |
|---|---|---|---|---|---|---|
| PAYMENT_MEMBERSHIP-V01-C01 | Header | Title / navigation | Thanh toán gói | Always | Static + module state | None |
| PAYMENT_MEMBERSHIP-V01-C02 | Body | Form/list/detail | Gói, chu kỳ, QR VietQR, ngân hàng nhận, số tài khoản, tên chủ tài khoản, số tiền, mã và nội dung chuyển khoản | Có yêu cầu awaiting_transfer/pending_review/succeeded/failed | Payment RPC | PAYMENT_MEMBERSHIP-BR01/BR03 |
| PAYMENT_MEMBERSHIP-V01-C03 | Action | Primary button/action | Yêu cầu QR / Đã chuyển khoản / Sao chép nội dung | Theo trạng thái hợp lệ | UI state | PAYMENT_MEMBERSHIP-FN01/FN03 |
| PAYMENT_MEMBERSHIP-V01-C04 | Feedback | Alert/toast/empty | Hướng dẫn, lỗi hoặc kết quả | Khi có trạng thái tương ứng | Result/Error | Không lộ stack trace/DB/API/secret |

## C. Trạng thái giao diện bắt buộc

| State | Điều kiện kích hoạt | UI phải hiển thị | Hành động cho người dùng |
|---|---|---|---|
| Initial | Lần đầu mở view | Skeleton hoặc trạng thái mặc định | Chờ dữ liệu |
| Loading | Đang gọi PAYMENT_MEMBERSHIP-FN01 hoặc API | Loading không gây layout shift, khóa duplicate action nếu cần | Chờ |
| Success | Kết quả hợp lệ | Dữ liệu/trạng thái mới và CTA tiếp theo | Tiếp tục flow |
| Empty | Không có dữ liệu | Lý do và CTA phù hợp | Tạo mới/quay lại |
| Validation error | Input sai | Field-level message bằng tiếng Việt/Nabitone | Sửa dữ liệu |
| Business error | Vi phạm rule | Message an toàn, không thuật ngữ nội bộ | Làm theo hướng dẫn |
| System error | Network/5xx/dependency lỗi | Retry + correlation id khi cần hỗ trợ | Thử lại/liên hệ hỗ trợ |
| Unauthorized/Forbidden | Thiếu đăng nhập/quyền | Login/no permission view | Đăng nhập/quay lại |
| Missing name | Hồ sơ SQLite không có full_name | Hướng dẫn cập nhật hồ sơ trước khi tạo QR | Cập nhật hồ sơ |
| Awaiting transfer | QR đã tạo | QR, số tiền, mã/memo, nút sao chép và “Đã chuyển khoản” | Chuyển tiền rồi xác nhận |
| Pending review | Khách đã xác nhận | Thông báo đang chờ Admin kiểm tra | Làm mới trạng thái |
| Rejected | Admin từ chối | Lý do từ chối an toàn | Tạo yêu cầu mới khi phù hợp |

## D. Tương tác và mapping đến function

| Interaction ID | Người dùng thao tác | Điều kiện | Hệ thống gọi | Thành công | Thất bại | Navigation |
|---|---|---|---|---|---|---|
| PAYMENT_MEMBERSHIP-V01-I01 | Chọn mua/gia hạn gói | Input và quyền hợp lệ | PAYMENT_MEMBERSHIP-FN01 | Refresh trạng thái Thanh toán, xác minh và quyền gói | Hiển thị lỗi an toàn | Giữ view hoặc tới bước kế tiếp |
| PAYMENT_MEMBERSHIP-V01-I02 | Tải lại dữ liệu | User có quyền xem | PAYMENT_MEMBERSHIP-FN02 hoặc API đọc | Cập nhật view | Empty/error state | Không đổi route |
| PAYMENT_MEMBERSHIP-V01-I03 | Bấm “Đã chuyển khoản” | Yêu cầu awaiting_transfer của chính khách | PAYMENT_MEMBERSHIP-FN03 | Chuyển sang pending_review, không đổi quyền | Hiển thị lỗi an toàn | Giữ view |

## E. Documented View Acceptance Requirements

| ID | Requirement | DD docs status | Implementation evidence |
|---|---|---|---|
| PAYMENT_MEMBERSHIP-VIEW-EV01-01 | View chỉ hiển thị đúng role và trạng thái. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| PAYMENT_MEMBERSHIP-VIEW-EV01-02 | Các state bắt buộc đều có thiết kế và test. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| PAYMENT_MEMBERSHIP-VIEW-EV01-03 | Action chính gọi đúng PAYMENT_MEMBERSHIP-FN01. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| PAYMENT_MEMBERSHIP-VIEW-EV01-04 | Error message không lộ thông tin kỹ thuật hoặc dữ liệu nhạy cảm. | Documented | Required in implementation/test phase; not executed in this DD docs pass |

---

<a id="payment_membership-v02"></a>
# PAYMENT_MEMBERSHIP-V02 — Payment approval queue

## A. Thông tin cơ bản

| Trường | Nội dung |
|---|---|
| Feature liên quan | PAYMENT_MEMBERSHIP-F02 |
| Route / entry point | /admin/payments, hoặc thanh thông báo ở đầu Admin shell |
| Loại view | Page / Screen / Widget / Admin view depending on platform surface |
| Actor được phép | Admin |
| Điều kiện truy cập | Theo quyền hiệu lực trong BD sections 3 và 5. |
| Hành vi khi không đủ quyền | Chặn ở route/use-case/API; UI chỉ hiển thị hướng dẫn an toàn. |
| Responsive | Mobile first for app surfaces; desktop/tablet for Admin surfaces. |
| Mockup / prototype | Optional future asset: BD v2.0 has no required mockup; view state/action contract is complete in this DD |

## B. Layout và thành phần giao diện

| Component ID | Khu vực | Loại | Nội dung / label | Hiển thị khi | Dữ liệu nguồn | Validation / rule |
|---|---|---|---|---|---|---|
| PAYMENT_MEMBERSHIP-V02-C01 | Header | Banner / navigation | Yêu cầu thanh toán chờ duyệt | Khi có pending_review | Admin alert RPC; làm mới 30 giây, resume và bấm làm mới | Chỉ payments.write thấy/đếm pending_review |
| PAYMENT_MEMBERSHIP-V02-C02 | Body | Form/list/detail | Mã giao dịch, tên khách, số tiền, nội dung chuyển khoản, thời điểm xác nhận, lý do từ chối | Actor có quyền | PAYMENT_MEMBERSHIP-API02 | PAYMENT_MEMBERSHIP-BR05 |
| PAYMENT_MEMBERSHIP-V02-C03 | Action | Primary button/action | Duyệt / từ chối sau đối chiếu VCB | pending_review hoặc pending cũ | UI state | PAYMENT_MEMBERSHIP-FN02 |
| PAYMENT_MEMBERSHIP-V02-C04 | Feedback | Alert/toast/empty | Hướng dẫn, lỗi hoặc kết quả | Khi có trạng thái tương ứng | Result/Error | Không lộ stack trace/DB/API/secret |

## C. Trạng thái giao diện bắt buộc

| State | Điều kiện kích hoạt | UI phải hiển thị | Hành động cho người dùng |
|---|---|---|---|
| Initial | Lần đầu mở view | Skeleton hoặc trạng thái mặc định | Chờ dữ liệu |
| Loading | Đang gọi PAYMENT_MEMBERSHIP-FN02 hoặc API | Loading không gây layout shift, khóa duplicate action nếu cần | Chờ |
| Success | Kết quả hợp lệ | Dữ liệu/trạng thái mới và CTA tiếp theo | Tiếp tục flow |
| Empty | Không có dữ liệu | Lý do và CTA phù hợp | Tạo mới/quay lại |
| Validation error | Input sai | Field-level message bằng tiếng Việt/Nabitone | Sửa dữ liệu |
| Business error | Vi phạm rule | Message an toàn, không thuật ngữ nội bộ | Làm theo hướng dẫn |
| System error | Network/5xx/dependency lỗi | Retry + correlation id khi cần hỗ trợ | Thử lại/liên hệ hỗ trợ |
| Unauthorized/Forbidden | Thiếu đăng nhập/quyền | Login/no permission view | Đăng nhập/quay lại |

## D. Tương tác và mapping đến function

| Interaction ID | Người dùng thao tác | Điều kiện | Hệ thống gọi | Thành công | Thất bại | Navigation |
|---|---|---|---|---|---|---|
| PAYMENT_MEMBERSHIP-V02-I01 | Admin review payment queue | Input và quyền hợp lệ | PAYMENT_MEMBERSHIP-FN02 | Refresh trạng thái Thanh toán, xác minh và quyền gói | Hiển thị lỗi an toàn | Giữ view hoặc tới bước kế tiếp |
| PAYMENT_MEMBERSHIP-V02-I02 | Tải lại dữ liệu | User có quyền xem | PAYMENT_MEMBERSHIP-FN02 hoặc API đọc | Cập nhật view | Empty/error state | Không đổi route |
| PAYMENT_MEMBERSHIP-V02-I03 | Bấm banner chờ duyệt | Có ít nhất một pending_review | Điều hướng tới hàng chờ | Hiển thị đúng danh sách chờ duyệt | Giữ view hiện tại nếu lỗi | /admin/payments |

## E. Documented View Acceptance Requirements

| ID | Requirement | DD docs status | Implementation evidence |
|---|---|---|---|
| PAYMENT_MEMBERSHIP-VIEW-EV02-01 | View chỉ hiển thị đúng role và trạng thái. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| PAYMENT_MEMBERSHIP-VIEW-EV02-02 | Các state bắt buộc đều có thiết kế và test. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| PAYMENT_MEMBERSHIP-VIEW-EV02-03 | Action chính gọi đúng PAYMENT_MEMBERSHIP-FN02. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| PAYMENT_MEMBERSHIP-VIEW-EV02-04 | Error message không lộ thông tin kỹ thuật hoặc dữ liệu nhạy cảm. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
