Commit de xuat: fix(ai): bo app-owned token cap va chan partial response

# Worklog - Bỏ cap token và hoàn thiện giao tiếp AI

## Thời gian

- Ngày: 2026-09-13
- Múi giờ: Asia/Ho_Chi_Minh (UTC+07:00)

## Phạm vi

- Bỏ cap `maxOutputTokens` do NanoBio truyền ở toàn bộ production AI flow.
- Chặn response Gemini bị kết thúc bằng `MAX_TOKENS` dù đã có text một phần.
- Gộp mọi text part visible, hỗ trợ object/JSON string ở Flutter và Edge.
- Sanitize free-form AI output trước display/history, không sửa câu hỏi người
  dùng và không sanitize structured JSON.
- Giữ các safety bound về kích thước, timeout, rate limit, history và image.

## Đã làm

- Làm `GeminiGenerationConfig.maxOutputTokens` optional và bỏ field khỏi chat,
  plan, NaBi Care, Voice, Food Scan, body metrics, nutrition, sleep và smoke
  call site.
- Thêm `extractGeminiResponseText` ở Flutter và `_shared/gemini_response.ts`
  ở Edge; thought parts bị loại bỏ và finish reason MAX_TOKENS được ưu tiên.
- Cập nhật `NabiAiBackendClient` để đọc object/JSON string và map
  `OUTPUT_TRUNCATED` thành lỗi typed.
- Thêm `AITextSanitizer`; chat stream buffer response hoàn chỉnh trước khi
  yield/accept/ghi history.
- Thêm regression tests cho sanitizer, câu hỏi nguyên bản, serialization,
  nhiều parts, JSON string, response rỗng và partial MAX_TOKENS.
- Cập nhật DD AI Chat hiện hành, fixbug note và smoke script. Không chạm file
  seed SQL đang do người dùng mở/chưa track.

## Bằng chứng

- `deno test --no-check ...`: PASS - 25/25.
- `deno test ...`: PASS - 25/25 và typecheck PASS.
- `deno fmt --check ...`: PASS - 7 file.
- `git diff --check`: PASS.
- `pwsh -NoProfile -File tools/test_gemini_connection.ps1`: PASS, sandbox
  Gemini backend trả response dài 9 ký tự.
- `supabase functions list --project-ref rnwohifdnylqfofkydfl`: cả hai Function
  ở trạng thái `ACTIVE`; Nabi version 7, Food Scan version 4.
- `flutter`, `dart`: không có executable trong môi trường; toàn bộ Dart/Flutter
  test và `flutter analyze` vì vậy chưa chạy được.

## Trạng thái triển khai

- Đã deploy `nabi-ai-generate` và `food-scan-analyze` lên sandbox.
- Generic Gemini smoke PASS.
- Chưa chạy Food Scan success smoke với session Plus/FamilyPlus hợp lệ.
- Chưa deploy mobile binary hoặc chạy device acceptance.

## Rủi ro và ghi chú

- Bỏ app-owned token cap không loại bỏ giới hạn nội tại của Gemini.
- Free-form chat/Voice bị làm sạch ký tự đặc biệt; structured JSON giữ nguyên để
  không phá schema downstream.
- Chat stream hiện chỉ phát sau khi provider hoàn tất để bảo đảm không lộ
  partial response; safety timeout vẫn giới hạn thời gian chờ.
- Thay đổi remote sandbox đã thực hiện; production/staging chưa được deploy.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - thay đổi đúng scope, có typed truncation, sanitizer
  tách biệt structured JSON và giữ nguyên safety bounds.
- Muc do hoan thanh task: hoàn tất code, test Edge, deploy sandbox và Gemini
  smoke; Dart/Flutter test/analyze và Food Scan paid success smoke chưa xác minh.
- Bang chung kiem chung: 25/25 Deno tests, Deno typecheck, format/diff check,
  sandbox Function ACTIVE và generic Gemini smoke PASS.
- Diem ton token/chua toi uu: thiếu Flutter/Dart SDK nên không có bằng chứng
  native; một phần docs lịch sử vẫn giữ cap vì đó là historical evidence.
- Cach toi uu cho phien sau: bổ sung Flutter SDK/device runner và token Plus để
  chạy full app suite, rồi thực hiện Food Scan success smoke có kiểm soát.
- Task-skill can doc lan sau: `.codex/task-skills/bugfix.md`
