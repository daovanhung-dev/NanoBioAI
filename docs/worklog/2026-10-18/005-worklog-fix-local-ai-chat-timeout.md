Commit de xuat: docs(worklog): ghi nhan fix local ai chat timeout

# Worklog - Fix timeout chat AI local

## Thời gian

- Ngày: 2026-10-18
- Bắt đầu: trước 20:06, giờ bắt đầu chính xác không còn trong context khi tiếp tục phiên.
- Kết thúc: khoảng 20:12, Asia/Ho_Chi_Minh
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: bugfix, test và docs
- Module chính: M05 AI / AI Chat / local runtime
- Yêu cầu gốc: sửa lỗi chat local không trả lời trên Android 11 với Qwen3 1.7B; tăng khoảng chờ token đầu, phân biệt timeout khỏi quá tải, log metadata an toàn, giữ quota và không gọi AI từ xa.

## Đã làm

- Tăng timeout mặc định của chat local từ 20 lên 120 giây. Với stream, giới hạn là thời gian im lặng giữa các token; token mới sẽ khởi động lại bộ đếm. Generator được inject trong unit test vẫn dùng timeout toàn lần gọi.
- Thêm exception và thông báo tiếng Việt riêng cho timeout suy luận local; lỗi timeout có thể thử lại và không bị xếp vào nhóm quá tải/cooldown.
- Giữ riêng lỗi model chưa sẵn sàng và runtime/quá tải. Log có model, trạng thái an toàn, loại lỗi và thời gian xử lý; không ghi nội dung hội thoại.
- Xác nhận repository chỉ thêm lịch sử và commit quota sau khi AI trả lời hợp lệ.
- Bổ sung regression tests cho token đầu sau 20 giây, khoảng nghỉ ngắn giữa các token, timeout, lỗi model/runtime, thông báo UI, lịch sử và quota. Bổ sung Android integration smoke với câu hỏi tổng hợp, không gắn quota gateway.
- Điều chỉnh cleanup smoke test để chờ các timer trạng thái của Nabi kết thúc trước khi widget bị dispose.
- Sửa câu hướng dẫn AI đã lỗi thời trong generator worklog để refresh không ghi lại đường Gemini/Dio sau khi app đã chuyển sang runtime local.

## File code/docs đã sửa

- `lib/app_versions/v1/services/ai/ai_chat_service.dart` - tăng idle timeout local lên 120 giây; ánh xạ timeout và log metadata an toàn.
- `lib/app_versions/v1/services/ai/ai_exceptions.dart` - thêm kiểu lỗi/copy timeout local.
- `lib/app_versions/v1/features/ai_chat/domain/repositories/ai_chat_repository_impl.dart` - giữ exception timeout có kiểu, không biến thành lỗi chung.
- `lib/app_versions/v1/features/ai_chat/presentation/controllers/ai_chat_controller.dart` - hiển thị thông báo timeout riêng và cho phép thử lại.
- `test/app_versions/v1/services/ai/ai_chat_service_test.dart`, `test/app_versions/v1/features/ai_chat/ai_chat_quota_test.dart`, `test/app_versions/v1/features/ai_chat/ai_chat_screen_error_test.dart` - regression cho timeout, model/runtime, UI và quota.
- `integration_test/ai_chat_local_runtime_smoke_test.dart` - smoke test Android bằng prompt tổng hợp và không gắn quota gateway.
- `.codex/tools/update_worklog_learning.py` - giữ hướng dẫn AI đồng bộ với runtime local khi tái tạo history.
- `docs/fixbug/local-ai-chat-timeout/001-fixbug-local-ai-chat-timeout.md` - phân tích nguyên nhân, thay đổi và giới hạn kiểm chứng thiết bị.

## Tài liệu liên quan

- `.codex/domains/ai-service.md`
- `.codex/workflows/bugfix.md`
- `docs/fixbug/local-ai-chat-timeout/001-fixbug-local-ai-chat-timeout.md`

## Commands

- `dart format <8 file Dart trong scope>`: PASS - không còn file cần format sau vòng cuối.
- `flutter test test/app_versions/v1/services/ai/ai_chat_service_test.dart test/app_versions/v1/features/ai_chat/ai_chat_quota_test.dart test/app_versions/v1/features/ai_chat/ai_chat_screen_error_test.dart`: PASS - 23 tests.
- Targeted `flutter analyze` trên 8 file Dart: PASS - không có issue.
- `flutter test integration_test/ai_chat_local_runtime_smoke_test.dart -d 12b304f9`: PARTIAL - lần đầu các assertion nhận câu trả lời local đã qua, nhưng runner đánh dấu test lỗi vì timer `NabiContextNotifier` chạy sau dispose; sau khi sửa cleanup, lần chạy sau không có model được chọn vì runner đã gỡ app sau lần chạy lỗi.
- `adb shell getprop ro.build.version.release`: PASS - thiết bị là Android 11; model Qwen3 1.7B đã trả lời ở lần smoke đầu.
- `pwsh -NoProfile -ExecutionPolicy Bypass -File .codex/tools/update_worklog_learning.ps1`: PASS - tạo lại 19 history/task-skill files.
- `python3 .codex/tools/update_worklog_learning.py --check`: PASS - 19 files khớp generator.
- `python3 tools/validate_docs_source_truth.py`: FAIL - thiếu `docs/audit/source_truth_manifest.json` trong worktree; không thuộc phạm vi chat local.
- `git diff --check`: PASS.
- `flutter run -d 12b304f9 --no-pub`: BLOCKED - Android trả `INSTALL_FAILED_USER_RESTRICTED: Install canceled by user`; không có app debug đang chạy để hot restart sau thay đổi.

## Lỗi/Rủi ro

- Đã fix: timeout suy luận local bị báo như quá tải sau 20 giây; nay chờ tối đa 120 giây không có token và có copy thử lại riêng.
- Chưa fix: chưa lặp lại được smoke test Android sau khi runner xóa lựa chọn/model cục bộ; không tải lại model 1.28 GB trong phiên này.
- Cần kiểm tra tiếp: cài/mở lại app debug trên Android, chọn model Qwen3 1.7B rồi chạy integration smoke để xác nhận lại câu trả lời và cleanup timer.

## Tỷ lệ hoàn thành

- Hoàn thành: thay đổi nguồn, thông báo, kiểm soát quota/lịch sử, regression suite và analyzer.
- Đang dở: xác nhận lặp lại trên thiết bị sau khi phục hồi model đã chọn.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - timeout tách khỏi overload, không đổi kiến trúc local/quota; regression test bao phủ 20 giây thực và fail path.
- Mức độ hoàn thành task: phần code và kiểm chứng cục bộ hoàn tất; smoke Android có bằng chứng trả lời một lần nhưng chưa lặp lại sau cleanup runner.
- Bằng chứng kiểm chứng: 23 focused tests, analyzer 8 file sạch, Android 11 với câu hỏi tổng hợp đã nhận câu trả lời; không dùng gateway quota trong smoke.
- Điểm tốn token/chưa tối ưu: integration runner làm mất lựa chọn model sau lần chạy lỗi và test cleanup cần một vòng sửa.
- Cách tối ưu cho phiên sau: giữ model/app state trên thiết bị khi chạy integration smoke; chạy lại sau khi chọn model trong app, không cần thay đổi test logic.
- Task-skill cần đọc lần sau: `.codex/task-skills/bugfix.md`
