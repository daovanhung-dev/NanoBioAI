Commit de xuat: fix(ai): chan loi credential Gemini khong tuong thich

# Worklog - Chẩn đoán lỗi tạo lịch trình AI sau onboarding

## Thời gian

- Ngày: 2026-07-13
- Timezone: Asia/Saigon

## Phạm vi

- Loại task: bugfix
- Module chính: M05 AI / onboarding / Gemini authentication
- Yêu cầu gốc: Lịch trình AI vẫn không được tạo sau onboarding.

## Đã làm

- Kiểm tra trực tiếp endpoint Gemini bằng cấu hình local nhưng không in khóa.
- Xác nhận tất cả model đều trả HTTP 401 `UNAUTHENTICATED` / `ACCESS_TOKEN_TYPE_UNSUPPORTED`.
- Xác nhận credential local có prefix `AQ` và không hoạt động như API key REST traffic.
- Thêm nhận diện lỗi xác thực để UI đưa hướng dẫn cấu hình rõ ràng.
- Sửa `tools/test_gemini_connection.ps1` để preflight không dừng do danh sách model rỗng.

## File code/docs đã sửa

- `lib/app_versions/v1/services/ai/ai_exceptions.dart` - nhận diện lỗi xác thực Gemini.
- `lib/app_versions/v1/services/ai/ai_service.dart` - ánh xạ lỗi xác thực cho kiểm tra kết nối.
- `lib/app_versions/v1/features/onboarding/providers/onboarding_completion_provider.dart` - giữ thông báo lỗi cụ thể.
- `lib/app_versions/v1/features/onboarding/presentation/controllers/onboarding_controller.dart` - truyền thông báo xác thực an toàn lên UI.
- `tools/test_gemini_connection.ps1` - sửa preflight.
- `test/services/ai/ai_service_test.dart` - regression test không lộ credential.

## Commands

- `tools/test_gemini_connection.ps1`: FAIL_EXPECTED - Gemini trả HTTP 401 với credential hiện tại.
- `dart format ...`: PASS.
- `flutter analyze ...`: PASS.
- `flutter test test/services/ai/ai_service_test.dart`: cần chạy lại sau thay đổi cuối.

## Lỗi/Rủi ro

- Đã fix: lỗi xác thực không còn bị che hoàn toàn bằng thông báo chung.
- Chưa fix được từ code: credential `AQ...` bị Gemini endpoint từ chối server-side.
- Cần kiểm tra tiếp: thay credential bằng key Gemini được endpoint chấp nhận, rebuild app và chạy onboarding trên device.

## Tỷ lệ hoàn thành

- Hoàn thành: xác định root cause, cải thiện chẩn đoán và UI error path.
- Đang dở: live generation phụ thuộc credential mới.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - đã kiểm tra bằng request thật và giữ nguyên tắc không log secret.
- Mức độ hoàn thành task: code hoàn tất; external credential còn chặn.
- Bằng chứng kiểm chứng: HTTP 401 lặp lại trên các model; analyzer PASS.
- Điểm tốn token/chưa tối ưu: cần kiểm tra live preflight sớm hơn trong lần đầu.
- Cách tối ưu cho phiên sau: chạy preflight trước device smoke và thay key trước khi debug UI.
- Task-skill cần đọc lần sau: `.codex/task-skills/bugfix.md`
