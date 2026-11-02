# Worklog - Fix tạo lộ trình AI cá nhân trên điện thoại

## Thời gian

- Ngày: 2026-11-01
- Bắt đầu: Không ghi nhận chính xác
- Kết thúc: Chưa hoàn tất runtime acceptance
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: bugfix
- Module chính: tạo lộ trình AI cá nhân trên Android và backend
- Yêu cầu gốc: sửa lỗi để app dùng AI server và tạo lộ trình cá nhân 7 ngày thành công trên điện thoại hiện tại.

## Đã làm

- Nạp context NanoBioAI theo `.codex/AGENTS.md`, project map, bugfix workflow, bugfix task skill và domain AI/onboarding.
- Bắt lỗi trên Xiaomi `220333QPG`, package `com.nanobioai.app`, giữ nguyên dữ liệu ứng dụng.
- Xác định lỗi SQLite `787` tại `GeneratedPlanRequestStore.prepareStaging`; chuyển upsert request cha vào cùng transaction ghi staging.
- Thêm trace ID và log request AI an toàn trong app.
- Sau khi staging được sửa, log backend ghi nhận các request AI với status `200`, `413` và `429`. `429` xác nhận giới hạn đang chặn luồng 7 ngày. App hiển thị 11/77 sự kiện đã lưu trước khi lượt tạo dừng.
- Sửa client để không retry dồn khi rate limited; lỗi 429 dừng ngay và được ánh xạ thành thông báo riêng.
- Nâng mặc định giới hạn backend trong source lên 30 request/phút theo kế hoạch đã được xác nhận bằng 429.
- Build APK debug mới. Chưa cài vào điện thoại vì backend runtime cần được cập nhật trước khi tiếp tục tạo lịch.

## File code/docs đã sửa

- `lib/core/network/backend_api_client.dart` - gửi `X-Trace-Id`, log metadata an toàn cho request AI.
- `lib/app_versions/v1/services/ai/generated_plan_request_store.dart` - ghi request cha và staging trong cùng transaction.
- `lib/app_versions/v1/services/ai/generated_plan_service.dart` - truyền định danh request vào thao tác staging nguyên tử.
- `lib/app_versions/v1/services/ai/ai_service.dart` và `ai_exceptions.dart` - dừng retry khi rate limited.
- `lib/app_versions/v1/features/onboarding/presentation/controllers/onboarding_controller.dart` và `review_step.dart` - ánh xạ rate limit; giữ log chẩn đoán an toàn, không đưa chi tiết debug vào snackbar.
- `backend/src/nanobio_backend/core/config.py`, `backend/.env.example` - mặc định 30 request/phút.
- Các test Flutter/backend tương ứng.
- `docs/fixbug/ai-schedule-mobile-service/001-fixbug-personalized-plan-generation.md` - nguyên nhân, thay đổi, bằng chứng và phần runtime còn thiếu.

## Kiểm chứng

- `LD_LIBRARY_PATH=/tmp/nabi-sqlite-ffi flutter test --reporter=compact test/services/ai/ai_service_test.dart test/app_versions/v1/services/ai/generated_plan_request_store_test.dart test/app_versions/v1/services/ai/generated_plan_service_auth_test.dart test/core/network/backend_ai_text_client_test.dart test/app_versions/v1/features/onboarding/onboarding_completion_flow_test.dart test/app_versions/v1/features/onboarding/review_step_error_message_test.dart`: PASS, 127 test.
- `backend/.venv/bin/pytest -q backend/tests/test_ai_ollama.py::test_ai_endpoint_enforces_per_user_technical_rate_limit`: PASS.
- `flutter analyze` trên 13 file Dart: PASS, không có issue.
- `backend/.venv/bin/ruff check backend/src/nanobio_backend/core/config.py backend/tests/test_ai_ollama.py`: PASS.
- `flutter build apk --debug`: PASS; artifact `build/app/outputs/flutter-apk/app-debug.apk`.
- Device runtime: staging không còn là điểm dừng; backend nhận AI POST. Lượt chạy kết thúc với rate limit, progress hiển thị 11/77 sự kiện đã lưu.
- Deployment/restart và kiểm chứng 7 ngày: CHƯA CHẠY. SSH không khóa máy chủ bị từ chối vì thiếu phương thức xác thực hợp lệ; không thay đổi service đang chạy.

## Lỗi/rủi ro còn lại

- Source local đặt mặc định 30/phút, nhưng server đang chạy chưa được đổi cấu hình; quan sát được `429` khi server giới hạn 6/phút.
- APK debug mới chưa cài lên điện thoại.
- Chưa đạt tiêu chí cuối: lộ trình 7 ngày chưa đủ 77/77 sự kiện và chưa có đối chiếu trace ID/status thành công ở app/server.
- Cần phiên SSH đã xác thực để triển khai biến môi trường, restart backend, cài APK và tiếp tục request đang có staging mà không xóa dữ liệu app.

## Tỷ lệ hoàn thành

- Hoàn tất: chẩn đoán phía app, sửa staging nguyên tử, xử lý rate limit trong client, source config backend, focused tests và build APK.
- Đang dở: cập nhật backend đang chạy, cài APK mới và xác nhận lộ trình 7 ngày thành công trên điện thoại.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: lỗi trước request server được xác định bằng mã SQLite và stack frame; tiếp đó phát hiện rate limit sau khi POST tới AI backend.
- Mức độ hoàn thành task: chưa hoàn tất vì chưa thể xác thực SSH và acceptance trên runtime.
- Bằng chứng kiểm chứng: 126 test Flutter, 1 test backend, analyzer, Ruff, APK debug build và log backend/device progress.
- Tối ưu phiên sau: tiếp tục từ APK đã build và staging đã lưu; chỉ cần cập nhật runtime rate limit rồi hoàn tất cùng request thay vì tạo lại hồ sơ.
- Task skill cần đọc lần sau: `.codex/task-skills/bugfix.md`.
