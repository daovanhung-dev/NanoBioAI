# List Features — [MODULE_CODE] / {{Tên module}}

> **Mục tiêu file:** Mô tả từng feature ở mức nghiệp vụ và luồng thực thi; từ đây Developer/QA biết feature bắt đầu ở đâu, phụ thuộc feature nào và hoàn thành trong điều kiện nào.

## 0. Thông tin tài liệu

| Trường | Giá trị |
|---|---|
| Module | `[MODULE_CODE]` |
| Overall liên quan | [Overall.md](Overall.md) |
| Phiên bản | `v{{x.y.z}}` |
| Cập nhật gần nhất | `{{YYYY-MM-DD}}` |

## 1. Feature inventory

| ID | Feature | Mục tiêu | Actor | Trigger | Priority | Depends on | Functions | Views | Status |
|---|---|---|---|---|---|---|---|---|---|
| `[MODULE]-F01` | `{{Tên feature}}` | `{{...}}` | `{{Role}}` | `{{...}}` | `P0` | `{{Fxx/none}}` | `[MODULE]-FN01` | `[MODULE]-V01` | `Draft` |

## 2. Bản đồ liên kết giữa feature

```mermaid
flowchart LR
    F01[[[MODULE]-F01<br/>{{Feature 01}}]] -->|{{Điều kiện/kết quả}}| F02[[[MODULE]-F02<br/>{{Feature 02}}]]
    F02 --> F03[[[MODULE]-F03<br/>{{Feature 03}}]]
    F01 -.Không bắt buộc.-> F04[[[MODULE]-F04<br/>{{Feature 04}}]]
```

| Feature nguồn | Quan hệ | Feature đích | Dữ liệu / trạng thái truyền qua | Điều kiện |
|---|---|---|---|---|
| `[MODULE]-F01` | `blocks / triggers / enriches / optional` | `[MODULE]-F02` | `{{...}}` | `{{...}}` |

---

<a id="f01"></a>
# [MODULE]-F01 — {{Tên feature}}

## A. Mục đích và phạm vi

| Hạng mục | Nội dung |
|---|---|
| Mục tiêu nghiệp vụ | `{{Kết quả mà feature phải tạo ra}}` |
| Actor chính | `{{Role}}` |
| Actor phụ / hệ thống | `{{Role / system}}` |
| Trigger | `{{Người dùng bấm / event đến / lịch chạy}}` |
| Phạm vi | `{{Bao gồm}}` |
| Không thuộc feature | `{{Không bao gồm}}` |
| Requirement nguồn | `{{BD-REQ-xx}}` |
| Rule áp dụng | `[MODULE]-BR01`, `[MODULE]-BR02` |
| View liên quan | `[MODULE]-V01`, `[MODULE]-V02` |
| Function liên quan | `[MODULE]-FN01`, `[MODULE]-FN02` |

## B. Điều kiện

| Loại | Nội dung |
|---|---|
| Tiền điều kiện | `{{Dữ liệu/tài khoản/quyền/trạng thái phải có trước}}` |
| Hậu điều kiện thành công | `{{Dữ liệu/trạng thái/event phải có sau khi thành công}}` |
| Hậu điều kiện thất bại | `{{Không đổi dữ liệu / rollback / trạng thái lỗi}}` |
| Idempotency | `{{Cách xử lý việc người dùng gửi lại cùng yêu cầu}}` |

## C. Luồng chính (happy path)

| Bước | Actor / hệ thống | Hành động | Kiểm tra / business rule | Dữ liệu đọc/ghi | Kết quả |
|---:|---|---|---|---|---|
| 1 | `{{Actor}}` | `{{Khởi tạo}}` | `{{...}}` | `{{...}}` | `{{...}}` |
| 2 | `{{View/API}}` | `{{Gửi yêu cầu}}` | `{{...}}` | `{{...}}` | `{{...}}` |
| 3 | `{{Service}}` | `{{Xử lý}}` | `[MODULE]-BR01` | `{{...}}` | `{{...}}` |
| 4 | `{{System}}` | `{{Hoàn tất}}` | `{{...}}` | `{{...}}` | `{{...}}` |

```mermaid
flowchart TD
    A([Bắt đầu]) --> B[{{Actor khởi tạo}}]
    B --> C{Đủ điều kiện?}
    C -- Không --> E[Trả lỗi theo mã lỗi]
    C -- Có --> D[Thực thi [MODULE]-FN01]
    D --> F[Đổi trạng thái / lưu dữ liệu]
    F --> G[Phát event / audit nếu cần]
    G --> H([Hoàn thành])
```

## D. Luồng thay thế và lỗi

| Mã luồng | Tại bước | Điều kiện | Hệ thống xử lý | Dữ liệu thay đổi | UI/API trả về | Test bắt buộc |
|---|---:|---|---|---|---|---|
| `[MODULE]-F01-ALT01` | 2 | `{{Actor quay lại/sửa dữ liệu}}` | `{{...}}` | `{{...}}` | `{{...}}` | `{{TC}}` |
| `[MODULE]-F01-ERR01` | 3 | `{{Rule bị vi phạm}}` | `{{chặn/rollback}}` | `{{Không ghi}}` | `{{error code}}` | `{{TC}}` |
| `[MODULE]-F01-ERR02` | 3 | `{{Dịch vụ ngoài lỗi}}` | `{{retry/queue/fallback}}` | `{{...}}` | `{{...}}` | `{{TC}}` |

## E. Quy tắc nghiệp vụ áp dụng

| Rule ID | Cách feature áp dụng | Bước kiểm tra | Message/mã lỗi |
|---|---|---:|---|
| `[MODULE]-BR01` | `{{Diễn giải ngắn, không định nghĩa lại rule}}` | 3 | `{{...}}` |

## F. Dữ liệu, API và event

| Loại | ID / tên | Vai trò trong feature | Đọc / Ghi | Ghi chú |
|---|---|---|---|---|
| Entity | `[MODULE]-E-{{name}}` | `{{...}}` | `Read/Write` | `{{...}}` |
| API | `[MODULE]-API01` | `{{...}}` | `Call/Expose` | `{{...}}` |
| Event | `{{event.name}}` | `{{producer/consumer}}` | `Publish/Consume` | `{{...}}` |

## G. Danh sách function thực thi

| Thứ tự | Function ID | Layer | Mục đích | Đồng bộ / bất đồng bộ | Bắt buộc |
|---:|---|---|---|---|---|
| 1 | `[MODULE]-FN01` | `Controller / Use case / Repository` | `{{...}}` | `Sync/Async` | `Có` |

## H. Tiêu chí chấp nhận (Acceptance Criteria)

- [ ] Với `{{precondition}}`, khi `{{actor}}` thực hiện `{{action}}`, hệ thống phải `{{outcome}}`.
- [ ] Khi `[MODULE]-BR01` bị vi phạm, hệ thống phải `{{block/response}}` và **không** `{{side effect không được xảy ra}}`.
- [ ] Khi external service lỗi, hệ thống phải `{{fallback/retry}}`.
- [ ] View `[MODULE]-V01` hiển thị đầy đủ Success / Loading / Empty / Error theo `Views.md`.
- [ ] Có test case cho happy path, từng business rule, từng error path và phân quyền.

## I. Phụ thuộc, rủi ro và câu hỏi mở

| Loại | Nội dung | Owner | Trạng thái |
|---|---|---|---|
| Dependency | `{{Module/API/đội khác}}` | `{{...}}` | `{{Open/Resolved}}` |
| Risk | `{{...}}` | `{{...}}` | `{{Open/Accepted/Mitigated}}` |
| Question | `{{...}}` | `{{...}}` | `{{Open/Answered}}` |

---

> Sao chép khối từ **[MODULE]-F01** cho từng feature mới, tăng mã tuần tự và cập nhật lại bảng `Feature inventory`.
