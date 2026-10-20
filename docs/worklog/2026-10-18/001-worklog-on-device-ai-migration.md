Commit de xuat: feat(ai): chuyen suy luan NanoBioAI sang model tren thiet bi

# Worklog - Chuyen NanoBioAI sang AI tren thiet bi

## Thoi gian

- Ngay: 2026-10-18
- Bat dau: Trước 14:43 Asia/Ho_Chi_Minh; mốc chính xác không còn trong context sau khi tiếp tục phiên.
- Ket thuc: 14:44 Asia/Ho_Chi_Minh
- Timezone: Asia/Ho_Chi_Minh

## Pham vi

- Loai task: Hoàn thiện coding theo plan đã được duyệt.
- Module chinh: AI runtime, chat/Nabi Care, lịch ăn/tập, Body Metrics, Nutrition, Sleep, Fitness Training, Voice Chat, Food Scan, native setup và web unsupported state.
- Yeu cau goc: Gỡ API key và đường gọi AI từ xa khỏi app NanoBioAI; dùng model cục bộ có bước chọn/tải lần đầu; giữ Supabase auth/sync/data/quota và không thay đổi Edge Function, secret hoặc triển khai.

## Da lam

- Tích hợp catalog/runtime local theo `ai_local` và `llamadart`, progress streaming, kiểm tra SHA-256, download tiếp tục/hủy/thử lại, lỗi thiếu dung lượng/tải/nạp; lưu lựa chọn model và gate thiết lập native lần đầu. Web bỏ qua bước setup native và từ chối tác vụ AI bằng thông báo rõ.
- Chuyển các luồng AI đã nêu sang hợp đồng `AiTextClient` trung lập. Food Scan tải model vision/projector ở lần quét đầu và gửi ảnh trực tiếp vào runtime cục bộ. Không còn fallback gọi AI từ xa.
- Gỡ `GeminiRestClient`, `NabiAiBackendClient` và cấu hình `GEMINI_*` khỏi app/build defines; cập nhật test hợp đồng để kiểm tra không có route transport AI từ xa. Giữ source Edge/server và script kiểm tra backend độc lập ngoài đường chạy app.
- Dùng context/tokenizer theo model được chọn; giới hạn lịch sử chat và rút gọn ứng viên lịch theo context. Giữ normalizer, kiểm tra mã catalog/trùng lặp, safety filters, fallback cục bộ và quota gateway hiện có.
- Cập nhật README, feature docs, AI Chat DD, privacy, Supabase boundary notes, `.codex` router/map/domain, checklist DD/coding và test contract. Không sửa Supabase SQL, Edge source, secret hay trạng thái triển khai.

## File code/docs da sua

- `lib/core/ai_local/`, `lib/app_versions/v1/services/ai/ai_text_client.dart` - thêm runtime/catalog, setup gate và provider-neutral contract.
- `lib/app_versions/v1/services/ai/`, `lib/app_versions/v1/features/`, `lib/app_versions/v3/features/food_scan/`, `lib/features/nabi/`, `lib/app/bio_ai_app.dart` - chuyển các consumer sang suy luận cục bộ và xử lý trạng thái không hỗ trợ/model lỗi.
- `lib/app_versions/v1/services/ai/gemini_rest_client.dart`, `lib/app_versions/v1/services/ai/nabi_ai_backend_client.dart` - xóa client REST/API-key và client Supabase AI Edge khỏi app source.
- `pubspec.yaml`, `pubspec.lock`, `macos/Flutter/GeneratedPluginRegistrant.swift`, `lib/core/config/app_env.dart`, `.env.example`, `tools/prepare_dart_defines.ps1` - khai báo runtime/plugin và bỏ cấu hình Gemini phía app.
- `test/` - cập nhật consumer tests, thêm local runtime/setup, local multimodal và no-remote-route contract; bỏ test của transport đã xóa.
- `README.md`, `SYSTEM_FEATURES_DOCUMENTATION.md`, `docs/DD/`, `docs/features/food-scan/`, `docs/release/google_play/PRIVACY_POLICY_PUBLIC_PAGE.md`, `docs/supabase/README.md`, `.codex/`, `docs/checklist/` - đồng bộ kiến trúc và trạng thái xác minh.
- `tools/validate_docs_source_truth.py` - thay các marker source hiện hành từ Gemini/Edge client sang local runtime.

## Tai lieu lien quan

- `docs/checklist/checklist_complete_DD.md`
- `docs/checklist/checklist_task_coding.md`
- `.codex/domains/ai-service.md`
- `docs/DD/ai_chat/Import_File.md`

## Commands

- `dart format <changed Dart files>`: PASS - 41 file được kiểm tra, một file format lại.
- `flutter analyze <changed Dart files>`: PASS - 41 items, không có issue.
- `flutter test <all changed test files>`: PASS - 98 tests.
- `flutter build apk --debug`: PASS - `build/app/outputs/flutter-apk/app-debug.apk`.
- `flutter build web --release`: PASS - JavaScript web build thành công; wasm dry-run báo incompatibility ở `flutter_secure_storage_web` (`dart:html`/`dart:js_util`) và cast trong `flutter_tts_web`.
- `flutter build linux --debug`: BLOCKED - CMake không tìm thấy `clang++`; cấu hình compiler của Linux target không nhận `g++` có sẵn.
- `flutter devices && adb devices -l`: PASS - chỉ có Linux desktop và Chrome; không có Android device/emulator để xác minh inference/setup thật.
- `git diff --check`: PASS.
- `pwsh -File .codex/tools/validate_codex_integrity.ps1`: FAIL do thiếu `docs/audit/source_truth_manifest.json` và link/path cũ trong hai tài liệu lịch sử `.codex`; không còn path Gemini trong `.codex/README.md` hoặc `.codex/PROJECT_MAP.md`.
- `grep` source scan cho Gemini URL/header, client remote, Edge route và `GEMINI_*` trong app/build config: PASS; chỉ còn pattern redaction an toàn trong `log_redactor.dart`.

## Loi/Rui ro

- Da fix: bỏ code transport từ xa/API-key khỏi app; lỗi model local không gọi AI server; cập nhật current source docs và source-truth markers.
- Chua fix: analyzer/build chưa chạy trên iOS, macOS, Windows; Linux native build bị chặn bởi compiler thiếu; cảnh báo wasm dry-run của plugin web có sẵn.
- Can kiem tra tiep: chọn/tải/nạp model và suy luận thật trên Android/iOS; kiểm tra cancel/resume/SHA/dung lượng trên thiết bị; Food Scan với ảnh thật; kiểm tra quota Supabase và lưu lịch end-to-end. Chưa có bằng chứng physical-device inference.

## Ty le hoan thanh

- Hoan thanh: Chuyển source app sang runtime AI cục bộ, thiết lập model native, web unsupported path, gỡ client remote/API key và cập nhật contract/docs.
- Dang do: Acceptance trên thiết bị, các nền tảng native chưa build, Food Scan ảnh thật, Supabase quota sandbox và xác minh lưu lịch end-to-end.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tốt - đường chạy app đã dùng hợp đồng trung lập, test/build cục bộ pass và không thay đổi server Supabase.
- Muc do hoan thanh task: hoàn thành code theo scope; acceptance native/inference thực tế còn pending.
- Bang chung kiem chung: 98 focused tests, targeted analyzer 41 items, Android debug APK, web release build, diff check và source scan pass.
- Diem ton token/chua toi uu: lần kiểm tra Codex integrity đọc thêm một số link lịch sử không thuộc scope; giá trị vẫn hữu ích để xác nhận không còn stale AI path trong current context.
- Cach toi uu cho phien sau: tiếp tục từ checklist/worklog này; dùng thiết bị Android với model nhỏ có sẵn và tài khoản QA để xác minh setup, inference, Food Scan và quota mà không dùng dữ liệu sức khỏe thật.
- Task-skill can doc lan sau: `.codex/task-skills/coding.md`
