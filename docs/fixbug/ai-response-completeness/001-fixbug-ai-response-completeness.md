Commit de xuat: fix(ai): bo app-owned token cap va chan partial response

# Fixbug - Giao tiếp AI bị cắt và còn giới hạn token phía ứng dụng

## Triệu chứng

Một số luồng AI tự truyền `maxOutputTokens` với các mức khác nhau. Parser
Gemini có thể nhận phần text đã sinh trước khi provider kết thúc bằng
`MAX_TOKENS`, khiến câu trả lời không hoàn chỉnh có nguy cơ được hiển thị hoặc
ghi vào lịch sử.

## Root cause đã xác nhận

1. `GeminiGenerationConfig` bắt buộc `maxOutputTokens`, và các call site của
   chat, Voice, kế hoạch, NaBi Care, Food Scan, dinh dưỡng, giấc ngủ và body
   metrics đặt cap riêng.
2. Flutter backend client chỉ đọc một dạng response object; Voice test seam
   cũng chỉ đọc text part đầu tiên.
3. Flutter và Edge Function chưa coi `finishReason = MAX_TOKENS` là lỗi khi
   response vẫn có text một phần.

## Đã sửa

- Đổi `GeminiGenerationConfig.maxOutputTokens` thành nullable và chỉ serialize
  khi caller chủ động cung cấp; mọi production AI call site hiện không truyền
  field này.
- Gộp toàn bộ visible text parts theo thứ tự, bỏ thought parts, hỗ trợ payload
  object hoặc JSON string.
- Chuẩn hóa `MAX_TOKENS` thành lỗi typed/`OUTPUT_TRUNCATED`; chat buffer toàn bộ
  response trước khi hiển thị, commit quota hoặc ghi history.
- Thêm `AITextSanitizer` cho free-form chat/Voice output. Sanitizer giữ tiếng
  Việt, số, whitespace, xuống dòng và dấu câu cơ bản; structured JSON không đi
  qua sanitizer; câu hỏi gốc của người dùng không bị chỉnh sửa.
- Giữ nguyên giới hạn kích thước request/response, timeout, rate limit, giới
  hạn history/image và các hàng rào chống lạm dụng.
- Cập nhật test, DD hiện hành và smoke script; không thay đổi schema hoặc seed
  SQL.

## Bằng chứng kiểm chứng

- `deno test supabase/functions/_shared/gemini_response_test.ts supabase/functions/nabi-ai-generate/handler_test.ts supabase/functions/food-scan-analyze/handler_test.ts`:
  PASS, 25/25.
- Deno typecheck trong cùng lệnh: PASS.
- `deno fmt --check` cho 7 Edge file và `git diff --check`: PASS.
- `pwsh -NoProfile -File tools/test_gemini_connection.ps1`: PASS, sandbox trả
  response AI không rỗng.
- Static production call-site check: không còn `maxOutputTokens:` trong các
  AI service/datasource production; field chỉ còn ở config nullable và test
  backward-compatibility.

## Triển khai

- Project sandbox `rnwohifdnylqfofkydfl`.
- `nabi-ai-generate`: deploy thành công, version 7, `ACTIVE`.
- `food-scan-analyze`: deploy thành công, version 4, `ACTIVE`.

## Giới hạn kiểm chứng

Flutter/Dart SDK không có trong môi trường hiện tại nên chưa chạy được toàn bộ
Dart/Flutter test, `flutter analyze` hoặc device smoke. Deno suite, Edge deploy
và sandbox Gemini smoke đã xác minh. Chưa thực hiện smoke Food Scan success path
với tài khoản Plus/FamilyPlus hợp lệ.
