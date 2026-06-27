# Views — [MODULE_CODE] / {{Tên module}}

> **Mục tiêu file:** Mô tả rõ từng view/màn hình/trạng thái hiển thị để UI/UX, Frontend, Backend và QA cùng hiểu: ai nhìn thấy gì, dữ liệu đến từ đâu, tương tác gọi function nào và lỗi được xử lý ra sao.

## 0. View inventory

| ID | Tên view | Route / entry point | Actor | Feature | Loại | Data source | Trạng thái | Mockup |
|---|---|---|---|---|---|---|---|---|
| `[MODULE]-V01` | `{{Tên view}}` | `{{/route hoặc modal}}` | `{{Role}}` | `[MODULE]-F01` | `Page / Modal / Drawer / Widget` | `[MODULE]-API01` | `Draft` | `assets/{{file}}` |

## 1. Navigation map

```mermaid
flowchart LR
    V01[[[MODULE]-V01<br/>{{Danh sách}}]] -->|{{Chọn item}}| V02[[[MODULE]-V02<br/>{{Chi tiết}}]]
    V02 -->|{{Thao tác chính}}| V03[[[MODULE]-V03<br/>{{Xác nhận}}]]
    V03 -->|{{Thành công}}| V04[[[MODULE]-V04<br/>{{Kết quả}}]]
```

---

<a id="v01"></a>
# [MODULE]-V01 — {{Tên view}}

## A. Thông tin cơ bản

| Trường | Nội dung |
|---|---|
| Feature liên quan | `[MODULE]-F01` |
| Route / entry point | `{{/path, deep link, button, notification}}` |
| Loại view | `Page / Modal / Drawer / Bottom sheet / Widget` |
| Actor được phép | `{{Role list}}` |
| Điều kiện truy cập | `{{login, permission, entity state}}` |
| Hành vi khi không đủ quyền | `{{Ẩn / redirect / 403 view}}` |
| Entry views | `[MODULE]-Vxx` |
| Exit views | `[MODULE]-Vxx` |
| Responsive | `{{Mobile / Tablet / Desktop}}` |
| Mockup / prototype | `assets/{{...}}` |

## B. Mục tiêu người dùng

- Người dùng vào view này để: `{{user goal}}`.
- Sau khi hoàn thành, người dùng có thể: `{{next action/outcome}}`.
- Hệ thống tuyệt đối không được để người dùng: `{{dangerous/confusing outcome}}`.

## C. Layout và thành phần giao diện

| Thứ tự | Component ID | Khu vực | Loại | Nội dung / label | Hiển thị khi | Dữ liệu nguồn | Validation / rule | Accessibility |
|---:|---|---|---|---|---|---|---|---|
| 1 | `V01-C01` | Header | `Title / Back button` | `{{...}}` | `always` | `static` | `—` | `{{aria label/focus}}` |
| 2 | `V01-C02` | Body | `Input / Select / Card` | `{{...}}` | `{{condition}}` | `{{field/API}}` | `[MODULE]-BR01` | `{{...}}` |
| 3 | `V01-C03` | Footer | `Primary button` | `{{Lưu / Gửi}}` | `{{form valid}}` | `—` | `{{disabled state}}` | `{{keyboard}}` |

### C.1 Quy tắc hiển thị dữ liệu

| Field UI | Field model/API | Format | Null/unknown | Masking | Quyền xem |
|---|---|---|---|---|---|
| `{{displayName}}` | `{{dto.field}}` | `{{VN date/currency/number}}` | `{{- / hidden / prompt}}` | `{{yes/no}}` | `{{roles}}` |

### C.2 Quy tắc nhập liệu

| Input | Required | Kiểu | Format | Validate client | Validate server | Error text | Rule ID |
|---|---:|---|---|---|---|---|---|
| `{{field}}` | `Y/N` | `text/select/date/file` | `{{...}}` | `{{...}}` | `{{...}}` | `{{Thông báo dễ hiểu}}` | `[MODULE]-BR01` |

## D. Trạng thái giao diện bắt buộc

| State | Điều kiện kích hoạt | UI phải hiển thị | Hành động cho người dùng | Tracking/log |
|---|---|---|---|---|
| Initial | `{{Lần đầu vào}}` | `{{skeleton/default}}` | `{{...}}` | `{{view_opened}}` |
| Loading | `{{Đang gọi dữ liệu}}` | `{{skeleton/spinner, không layout shift}}` | `{{khóa action nếu cần}}` | `{{latency}}` |
| Success | `{{Có dữ liệu / action thành công}}` | `{{data/toast/result}}` | `{{next action}}` | `{{success event}}` |
| Empty | `{{Không có dữ liệu}}` | `{{minh họa + message + CTA}}` | `{{create/retry/back}}` | `{{empty_viewed}}` |
| Validation error | `{{Input sai}}` | `{{inline error, giữ dữ liệu đã nhập}}` | `{{sửa field}}` | `{{validation code}}` |
| Business error | `{{Rule vi phạm}}` | `{{message không kỹ thuật}}` | `{{hướng dẫn xử lý}}` | `{{business error code}}` |
| System error | `{{5xx/network}}` | `{{retry + safe error}}` | `{{thử lại/liên hệ hỗ trợ}}` | `{{correlation id}}` |
| Unauthorized | `{{401}}` | `{{login prompt}}` | `{{đăng nhập}}` | `{{auth redirect}}` |
| Forbidden | `{{403}}` | `{{no permission view}}` | `{{quay lại}}` | `{{security event nếu cần}}` |
| Offline | `{{Không có mạng}}` | `{{offline info}}` | `{{retry/queue}}` | `{{offline event}}` |

## E. Tương tác và mapping đến function

| Interaction ID | Người dùng thao tác | Component | Điều kiện | Hệ thống gọi | Thành công | Thất bại | Navigation |
|---|---|---|---|---|---|---|---|
| `V01-I01` | `{{Bấm Lưu}}` | `V01-C03` | `{{form valid}}` | `[MODULE]-FN01` | `{{toast + refresh}}` | `{{show error}}` | `[MODULE]-V02` |
| `V01-I02` | `{{Bấm Hủy}}` | `V01-C04` | `always` | `{{none / FN}}` | `{{...}}` | `—` | `[MODULE]-Vxx` |

## F. Data fetching và cache

| Data need | Function/API | Fetch time | Cache policy | Refresh trigger | Loading strategy | Failure fallback |
|---|---|---|---|---|---|---|
| `{{Danh sách}}` | `[MODULE]-FNxx` / `[MODULE]-APIxx` | `onEnter/onDemand` | `{{TTL/no cache}}` | `{{pull-to-refresh/event}}` | `{{skeleton}}` | `{{cached/empty/retry}}` |

## G. Copywriting, UX và accessibility

| Hạng mục | Quy định |
|---|---|
| Tiêu đề | `{{Ngắn, nêu mục tiêu màn}}` |
| CTA chính | `{{Động từ rõ hành động}}` |
| Message lỗi | `{{Không lộ stack trace/DB/API; có hướng dẫn}}` |
| Xác nhận hành động rủi ro | `{{Modal + hậu quả + hủy/xác nhận}}` |
| Focus/keyboard | `{{Tab order, Enter/Escape}}` |
| Screen reader | `{{label/description/live region}}` |
| Màu sắc | `{{Không chỉ dùng màu để truyền tải trạng thái}}` |

## H. Acceptance checklist cho QA/UI

- [ ] Mọi component trong bảng layout xuất hiện đúng role và điều kiện.
- [ ] Tất cả state tại mục D có thiết kế và kiểm thử.
- [ ] Các interaction gọi đúng `[MODULE]-FNxx` và điều hướng đúng view đích.
- [ ] Validation client không thay thế validation server.
- [ ] Error message không để lộ thông tin hệ thống nhạy cảm.
- [ ] View dùng được ở viewport/thiết bị đã nêu và bằng bàn phím nếu áp dụng.
- [ ] Màn hình không hiển thị dữ liệu không thuộc tenant/role của actor.

---

> Sao chép khối `[MODULE]-V01` cho từng page/modal/widget. Link mockup, ảnh hoặc prototype vào `assets/`.
