Commit de xuat: docs(issue): ghi nhan lech contract Early Access API

# Admin Web gửi pagination và lý do cập nhật Early Access không hợp lệ

## Tóm tắt

- Các route Early Access được frontend gọi đều tồn tại.
- Hợp đồng tham số không khớp ở trang đầu: giao diện gửi `page=0`, backend chỉ nhận `page >= 1`. Form trạng thái cũng cho phép lý do 1–4 ký tự dù schema backend yêu cầu tối thiểu 5 ký tự.

## Kỳ vọng và thực tế

- Kỳ vọng: request trang đầu và form hợp lệ theo UI được backend chấp nhận.
- Thực tế:
  - `EventInfoPage` khởi tạo page bằng 0 và truyền nguyên giá trị qua `fetchEarlyAccessLeads`; backend trả `422` cho `page=0`, nên danh sách mặc định không tải được.
  - Form chỉ khóa khi lý do trống; lý do 1–4 ký tự được gửi lên nhưng schema backend từ chối với `422`.

## Mức độ ảnh hưởng

- Severity: high.
- Người vận hành không tải được danh sách Early Access ở trang đầu; nếu pagination được sửa riêng, cập nhật trạng thái vẫn có thể thất bại với lý do ngắn.

## Cách tái hiện hoặc xác minh

1. Mở màn Thông tin sự kiện; frontend gọi `GET /api/v1/admin/early-access/leads?q=&page=0&page_size=25`.
2. Backend khai báo `page` có mặc định 1 và `ge=1`, nên request `page=0` không qua validation và FastAPI trả lỗi validation `422`.
3. Mở form đổi trạng thái, nhập lý do từ 1 đến 4 ký tự rồi lưu.
4. Frontend gửi PATCH, còn Pydantic yêu cầu `reason` tối thiểu 5 ký tự; reason 1–4 ký tự qua kiểm tra frontend rồi bị schema từ chối với `422`.

## Bằng chứng

- `admin-web/src/pages/EventInfoPage.tsx:28-47,70-73` - page khởi tạo/reset về 0 và truyền vào API.
- `admin-web/src/lib/admin-api.ts:114-121` - gửi nguyên `page` thành query parameter.
- `backend/src/nanobio_backend/modules/admin/router.py:365-379` - endpoint chỉ chấp nhận `page >= 1`.
- `admin-web/src/pages/EventInfoPage.tsx:76-84,214-228` - form chỉ yêu cầu reason không rỗng.
- `backend/src/nanobio_backend/modules/admin/models.py:38-41` - schema yêu cầu reason từ 5 đến 300 ký tự.

## Hướng xử lý đề xuất

- Chọn một quy ước pagination (zero-based hoặc one-based) và chuyển đổi nhất quán ở ranh giới API.
- Đồng bộ kiểm tra độ dài reason giữa UI/client và Pydantic schema.
- Thêm kiểm tra contract cho trang đầu, chuyển trang và cập nhật trạng thái.

## Files/log liên quan

- `admin-web/src/pages/EventInfoPage.tsx`
- `admin-web/src/lib/admin-api.ts`
- `backend/src/nanobio_backend/modules/admin/router.py`
- `backend/src/nanobio_backend/modules/admin/models.py`

## Liên kết

- Worklog: ../../worklog/2026-10-31/004-worklog-admin-web-api-contract-audit.md
