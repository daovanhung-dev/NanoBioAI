Commit de xuat: fix(sleep-safety): chinh validator so lien he E.164

# Fix bug — Validator số điện thoại contact an toàn

## Hiện tượng

Luồng thêm contact an toàn từ chối số điện thoại hợp lệ trước khi có thể hoàn
tất bước xác minh. Không lưu số thật, OTP hoặc dữ liệu contact vào tài liệu này.

## Nguyên nhân

CHECK constraint của bảng và hai overload `upsert_sleep_safety_contact` dùng
regex có escape thừa (`\\+`). Với standard-conforming string, regex engine đọc
đó thành ký tự backslash literal được lặp bởi `+`, nên không khớp dấu cộng
literal trong E.164.

## Sửa

- Canonical build script dùng dấu cộng literal trong character class: `'^[+][1-9][0-9]{7,14}$'`.
- Migration `20261006100000_m31_contact_phone_regex_fix.sql` thay constraint và
  cập nhật đúng hai RPC theo guard kiểm tra definition hiện tại; dừng nếu schema
  đã drift ngoài pattern dự kiến.
- Migration chỉ sửa schema/function definition; không insert/update contact rows.

## Kiểm chứng

- Staging remote xác nhận regex chấp nhận mẫu E.164 tổng hợp, table constraint
  đã sửa, cả hai RPC đã sửa và không còn RPC nào chứa pattern lỗi.
- Migration đã xuất hiện trong remote migration history.
- Focused Flutter suite sau cập nhật contract: 21/21 PASS.
- Staging không có contact QA được tạo trong lượt này; OTP và cuộc gọi chưa chạy.

## Giới hạn

PITR và physical backup của staging không có. Recovery dựa trên migration
transactional, schema additive và forward-fix; phone fallback flag được khôi
phục về `false`, Zalo vẫn `false`.
