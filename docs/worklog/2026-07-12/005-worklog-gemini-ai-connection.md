Commit de xuat: docs(worklog): ghi nhan fix ket noi Gemini AI

# Worklog - Fix kết nối Gemini cho toàn bộ tác vụ AI

## Thời gian

- Ngày: 2026-07-12
- Bắt đầu: 11:50
- Kết thúc: 12:22
- Timezone: Asia/Saigon

## Phạm vi

- Loại task: bugfix
- Module chính: M05 AI / Meal / Exercise / AI Chat / runtime config
- Yêu cầu gốc: đọc `AGENTS.md`, lấy context coding, đọc `.env`, sửa lỗi không kết nối AI và bảo đảm các tác vụ AI hoạt động sau kiểm tra.

## Đã làm

- Đọc context dự án, workflow bugfix, AI domain và docs workflow.
- Kiểm tra `.env` theo cách mask; xác nhận key/model/base URL có dữ liệu mà không in secret.
- Xác định hai root cause: key AI không được bắt buộc truyền vào runtime và SDK Gemini cũ không phù hợp đường xác thực hiện tại.
- Thay SDK cũ bằng `GeminiRestClient` dùng Dio + REST `generateContent` + `x-goog-api-key`.
- Đồng bộ onboarding check, meal plan, exercise task và AI Chat sang client chung.
- Giữ validate/fallback/retry/model cooldown; thêm history chat giới hạn 16 message.
- Bắt buộc Auth + AI config trong run/build scripts; thêm VS Code launch profile.
- Thêm PowerShell Gemini live preflight không in key.
- Bổ sung focused regression/contract tests và cập nhật hướng dẫn.
- Loại bỏ dependency cũ khỏi `pubspec.yaml`/`pubspec.lock`.

## File code/docs đã sửa

- `lib/app_versions/v1/services/ai/gemini_rest_client.dart` - tạo - transport Gemini REST và error mapping.
- `lib/app_versions/v1/services/ai/ai_service.dart` - sửa - meal/exercise/onboarding dùng client REST.
- `lib/app_versions/v1/services/ai/ai_chat_service.dart` - sửa - chat REST và bounded history.
- `lib/app_versions/v1/services/ai/ai_exceptions.dart` - sửa - transient mapping theo `GeminiApiException`.
- `tools/run_v2.ps1` - sửa - bắt buộc `GEMINI_API_KEY`.
- `tools/build_authenticated.ps1` - sửa - chặn build thiếu AI key.
- `tools/test_gemini_connection.ps1` - tạo - live preflight key/model.
- `.vscode/launch.json` - tạo - truyền `.env` khi debug app/admin.
- `test/services/ai/gemini_rest_client_test.dart` - tạo - transport + service integration tests.
- `test/services/ai/ai_service_test.dart` - sửa - exception tests theo client mới.
- `test/tools/*` - sửa/tạo - run/build/preflight contracts.
- `README.md`, `.env.example`, AI README - sửa - hướng dẫn run/build có AI.
- `docs/fixbug/gemini-ai-connection/001-fixbug-gemini-ai-connection.md` - tạo.
- `docs/test/gemini-ai-connection/001-test-gemini-ai-connection.md` - tạo.

## Tài liệu liên quan

- `.codex/domains/ai-service.md`
- `.codex/workflows/bugfix.md`
- `docs/fixbug/ai-chat-dotenv-uninitialized/001-fixbug-ai-chat-dotenv-uninitialized.md`

## Commands

- Masked `.env` inventory + secret scan: PASS - key có dữ liệu, không rò rỉ ngoài `.env`.
- Static Dart delimiter/import scan: PASS - 10 file.
- YAML/JSON parse: PASS - `pubspec.yaml`, `.vscode/launch.json`.
- AI path audit: PASS - onboarding/meal/exercise/chat dùng client mới.
- Live Gemini request: BLOCKED - sandbox DNS `gaierror`.
- `dart format`, `flutter analyze`, `flutter test`, `flutter build`: SKIPPED - không có Dart/Flutter SDK.
- PowerShell scripts: SKIPPED - không có PowerShell.
- `.codex/tools/update_worklog_learning.ps1`: SKIPPED - không có PowerShell.

## Lỗi/Rủi ro

- Đã fix: key loại hiện tại không còn đi qua SDK cũ; runtime/build không còn âm thầm thiếu key; tất cả đường AI dùng chung transport.
- Chưa fix: không có bằng chứng live API, compile, Flutter test và device smoke trong sandbox.
- Cần kiểm tra tiếp: chạy preflight, targeted tests, analyze/build và thao tác onboarding/chat/tạo plan trên thiết bị có mạng.

## Tỷ lệ hoàn thành

- Hoàn thành: source fix, runtime guard, preflight, regression source, docs và secret scan.
- Đang dở: live Gemini/toolchain/device acceptance do môi trường không hỗ trợ.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - sửa đúng lớp transport và lỗi truyền config, không bundle/lộ secret.
- Mức độ hoàn thành task: hoàn thành code; acceptance live bị chặn bởi DNS/toolchain.
- Bằng chứng kiểm chứng: source contracts, fake transport integration, masked env audit và secret scan.
- Điểm tốn token/chưa tối ưu: vừa phải do phải audit nhiều luồng AI và script build.
- Cách tối ưu cho phiên sau: chạy preflight đầu tiên trên máy có mạng, sau đó targeted tests và device smoke trước broad analyze.
- Task-skill cần đọc lần sau: `.codex/task-skills/bugfix.md`
