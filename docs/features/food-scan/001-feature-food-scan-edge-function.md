Commit de xuat: feat(food-scan): them edge function phan tich mon an

# Food Scan Edge Function

## Mục tiêu

Food Scan sử dụng Edge Function riêng `food-scan-analyze` để chuyển tiếp hai
operation AI hiện có tới Gemini:

- `vision`: nhận diện thực phẩm từ một ảnh inline.
- `health`: đánh giá bữa ăn theo health context đã được app chuẩn bị.

Prompt, parser, nutrition resolver, health rule engine và local persistence vẫn
thuộc về app Flutter.

## Runtime contract

Function nhận `POST` với JWT hợp lệ và body gồm `operation`, `model`, `contents`,
`generation_config` và tùy chọn `system_instruction`. `vision` bắt buộc có đúng
một ảnh inline dạng `image/*`; `health` không nhận ảnh.

Function kiểm tra quyền Plus/FamilyPlus qua `effective_user_access`, giới hạn
request theo user và không ghi ảnh, prompt, health context hoặc AI response vào
log hay database. Response thành công giữ dạng `{ success: true, text }` để
không làm thay đổi parser Food Scan.

Gate phía app dùng `hasPaidAccess` để giữ đúng quyền Plus và FamilyPlus. Ảnh
được chuẩn hóa thành JPEG, xóa EXIF/GPS và tự giảm quality/kích thước xuống tối
đa 900.000 byte trước khi encode base64, chừa ngân sách cho prompt và JSON
envelope của request.

## Client wiring

`FoodScanAiDatasource` dùng `NabiAiBackendClient` với function name
`food-scan-analyze` và gửi `operation=vision` hoặc `operation=health`. Các
client AI khác tiếp tục dùng `nabi-ai-generate`.

## Triển khai

Đã deploy vào Supabase project `rnwohifdnylqfofkydfl`. Function yêu cầu các
secret runtime hiện có: `SUPABASE_URL`, `SUPABASE_ANON_KEY`,
`SUPABASE_SERVICE_ROLE_KEY`, `GEMINI_API_KEY`, `GEMINI_MODEL` và
`GEMINI_ALLOWED_MODELS`.

Không có schema hoặc migration mới. App chỉ tạo nutrition log và event
`food_scan.confirmed_consumed` sau khi người dùng xác nhận đã ăn.
