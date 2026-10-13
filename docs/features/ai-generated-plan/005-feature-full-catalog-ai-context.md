Commit de xuat: feat(ai): gui day du catalog ma ten vao prompt

# Gửi đầy đủ catalog SQLite cho AI tạo lịch

## Mục tiêu

Để mỗi lượt AI lập lịch có thể chọn từ toàn bộ danh mục hiện có bằng mã và tên. Ứng dụng vẫn gọi Supabase Edge Function; Edge Function giữ Gemini API key và gọi Gemini.

## Luồng hiện tại

1. `GeneratedPlanService` tải bundle qua `AiCatalogLocalDatasource.loadScheduleCatalogBundle()`.
2. `AiCatalogDao` đọc mọi hàng trong `meal_catalog` và `exercise_catalog`, không thêm điều kiện `is_active`, plan eligibility, dị ứng, bệnh, chất lượng dữ liệu hay thiết bị.
3. Trong mỗi một trong 7 lượt tạo bữa, prompt có nguyên danh sách món dạng `[{code, name}]`. Trong mỗi một trong 7 lượt vận động, prompt chứa tất cả bài tập dạng `[{code, name}]`, nhóm thành `selectable` và `context_only` theo trạng thái `is_active` trong SQLite.
4. Catalog hiện tại là 163 món đang hoạt động và 40 bài tập: 16 bài M02 đang hoạt động để chọn, 24 bài M32 đang chờ rà soát chỉ làm ngữ cảnh. Không được chọn mã `context_only`; `ExerciseTasksAiNormalizer` từ chối mã inactive nếu AI trả về.
5. AI chỉ trả ngày, loại bữa và mã món hoặc ngày và mã bài. Ứng dụng kiểm tra mã/ngày/số lượng, dựng chi tiết chuẩn từ SQLite, giữ staging cho các lượt đã hợp lệ, rồi ghi kế hoạch nguyên tử khi đủ 35 bữa và 14 hoạt động.

## Giới hạn request

- Ngưỡng ký tự 32.000 ở prompt và Edge Function đã được gỡ. Danh sách không bị cắt âm thầm.
- Edge Function dùng `models.get` để lấy `inputTokenLimit`/`outputTokenLimit` và `models.countTokens` để đếm toàn bộ request, kể cả system instruction và generation config, trước `generateContent`.
- Request body bị chặn ở 1.500.000 byte. Vượt giới hạn model trả lỗi HTTP 413 với mã `MODEL_CONTEXT_LIMIT_EXCEEDED`; vượt dung lượng request trả mã `REQUEST_TOO_LARGE`. Flutter ánh xạ cả hai lỗi thành thông báo rõ ràng. Không có giới hạn token giả lập ở ứng dụng.
- Token preflight chỉ gửi nội dung đến Gemini qua backend có credential; thiết bị không gọi API Gemini trực tiếp.

## Quyền chọn và giới hạn dữ liệu

- Danh sách món được gửi trọn vẹn và chỉ có mã/tên. Ứng dụng vẫn xác thực món đang hoạt động và kiểm tra loại bữa khi chuẩn hóa kết quả.
- Danh sách bài tập được gửi trọn vẹn. Chỉ trạng thái active cho phép lưu; trạng thái inactive được AI nhìn thấy để tham khảo nhưng không có quyền chọn.
- Mã và tên không đủ dữ kiện để xác minh dinh dưỡng, dị ứng, chống chỉ định hoặc mức phù hợp y khoa. Luồng này chỉ hỗ trợ wellness; không khẳng định lịch đã được xác minh y tế.
- Thay đổi prompt dùng phiên bản staging `personal_schedule_14_call_v2_full_catalog`, làm vô hiệu staging cũ được tạo theo prompt trước.

## Kiểm chứng

- Prompt với asset nguồn xác nhận đủ 163 cặp mã/tên và không có trường catalog khác.
- DAO test dùng query executor giả để xác nhận hai truy vấn không có `where`; dữ liệu từ asset món và seed M02/M32 có 163 món/40 bài, prompt giữ toàn bộ cặp.
- Prompt bài tập xác nhận 16/24 được chia đúng hai nhóm; normalizer từ chối mã inactive.
- Luồng kế hoạch xác nhận 14 lượt theo thứ tự, 35 bữa/14 hoạt động và một lần commit nguyên tử.
- Deno test xác nhận nội dung trên 32.000 ký tự được chuyển tiếp, request trên 1.500.000 byte bị chặn, token preflight kiểm tra cả input và output, và không cần gọi Gemini thật trong test.

## Trạng thái xác nhận

Kiểm tra source, prompt, token preflight và test cục bộ đã hoàn tất. Chưa deploy Edge Function, chưa gọi Gemini thật, chưa xác nhận trên thiết bị hoặc quota Supabase.
