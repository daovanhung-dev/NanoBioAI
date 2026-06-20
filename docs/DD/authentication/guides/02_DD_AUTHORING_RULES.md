# Quy tắc soạn DD

## 1. Metadata bắt buộc đầu file

- DD ID
- Tên
- BD nguồn / requirement IDs
- Version, status, owner/reviewer nếu dự án dùng
- Dependencies và affected module

## 2. Cách viết

- Dùng điều kiện kiểm chứng được: “must”, “không được”, “khi… thì…”.
- Một rule chỉ có một ý chính, tránh câu mơ hồ như “xử lý phù hợp”.
- Tên bảng, state, route, method đặt trong backticks.
- Phân biệt business rule và implementation choice.
- Không đặt secret, key, token hay sample credentials vào DD.
- Dùng diagram/text flow khi hành vi có nhiều actor hoặc status.

## 3. Security checklist

- Ownership đến từ Auth UUID, không từ input UI.
- RLS/permission nêu rõ SELECT/INSERT/UPDATE/DELETE.
- Secret chỉ ở trusted server.
- Error UI không lộ table, SQL, raw exception, account existence.
- Sensitive health data chỉ viết đúng scope đã được user cung cấp.

## 4. Change control

Khi BD đổi: cập nhật BD version, traceability map, DD feature ảnh hưởng, migration/code/test docs. Không sửa DD âm thầm nếu thay đổi behavior đã triển khai.

## 5. Anti-pattern

- Một file DD dài mô tả tất cả auth/onboarding/database không có entry point.
- UI gọi Supabase trực tiếp bỏ qua repository.
- DD chỉ có happy path, không có route guard/RLS/lỗi.
- Dùng test case chung chung “test works”.
