Commit de xuat: docs(worklog): ghi nhận chẩn đoán lỗi tạo lịch onboarding

# Worklog - Chẩn đoán lỗi tạo lịch onboarding trên Xiaomi

## Thời gian

- Ngày: 2026-10-13
- Bắt đầu: 14:35
- Kết thúc: 15:05
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: Bugfix, diagnostics, focused tests, device reproduction attempt.
- Module chính: onboarding, AI generated plan, meal/exercise candidate filtering.
- Yêu cầu gốc: thêm log an toàn trước khi bắt lỗi, tìm và sửa nguyên nhân không tạo được lịch trên Xiaomi.

## Đã làm

- Bổ sung log stage, exception type, stack trace đã lọc và số lượng candidate/catalog; gắn mã lỗi riêng cho thiếu ứng viên.
- Sửa ánh xạ lỗi Review để người dùng biết hồ sơ đã lưu nhưng lịch chưa tạo; giữ thông báo cụ thể khi candidate thiếu.
- Kiểm tra tổng hợp SQLite trên Xiaomi: hồ sơ còn `in_progress`, không có bữa/lịch đã ghi; 163 món active không có dinh dưỡng hoặc metadata ràng buộc đã xác minh; 16 bài vận động active chưa có trạng thái condition-reviewed.
- Xác định selector dừng trước AI khi hồ sơ có ràng buộc cần bằng chứng; không nới bộ lọc.
- Chạy app debug từ source trên Xiaomi. Một hot reload báo thành công, sau đó kết nối Flutter bị mất; lần `flutter run` cuối build/cài lại source hiện tại. App mở tại trang bắt đầu, không còn màn hình Review đang dở. Controller khởi tạo state trống nên không thể phát lại request bằng biểu mẫu đã lưu nguyên trạng; không bấm tạo, không gửi request AI, không tiêu thụ quota.

## File code/docs đã sửa

- `lib/app_versions/v1/features/onboarding/presentation/controllers/onboarding_controller.dart` - log stack đã lọc trước khi bọc lỗi.
- `lib/app_versions/v1/features/onboarding/presentation/widgets/review_step.dart` - log tại UI boundary và ánh xạ thông báo lỗi.
- `lib/app_versions/v1/services/ai/generated_plan_service.dart` - log giai đoạn/count và mã lỗi thiếu candidate.
- `test/app_versions/v1/features/onboarding/onboarding_completion_flow_test.dart` - hồi quy cho thiếu candidate và không đánh dấu hoàn tất.
- `test/app_versions/v1/features/onboarding/review_step_error_message_test.dart` - hồi quy ánh xạ thông báo.
- `test/app_versions/v1/services/ai/generated_plan_service_auth_test.dart` - hồi quy log stage, count, mã lỗi và stack.
- `docs/fixbug/onboarding-unverified-catalog-block/001-fixbug-onboarding-unverified-catalog-block.md` - bằng chứng, kết luận và giới hạn.
- `docs/worklog/2026-10-13/004-worklog-onboarding-plan-diagnosis.md` - worklog phiên.

## Tài liệu liên quan

- `.codex/workflows/bugfix.md`
- `.codex/domains/ai-service.md`
- `.codex/domains/onboarding.md`
- `.codex/history/SESSION_QUALITY_REVIEW.md`

## Commands

- `dart format <6 tệp Dart đã sửa>`: PASS.
- `flutter test test/app_versions/v1/features/onboarding/onboarding_completion_flow_test.dart test/app_versions/v1/features/onboarding/review_step_error_message_test.dart test/app_versions/v1/services/ai/generated_plan_service_auth_test.dart`: PASS, 26 tests.
- `flutter analyze <6 tệp Dart đã sửa>`: PASS, không có vấn đề.
- `pwsh -NoLogo -NoProfile -File .codex/tools/validate_codex_integrity.ps1`: FAIL do thiếu `docs/audit/source_truth_manifest.json` và stale paths ở history/task-skill files có sẵn, không thuộc các file code/docs mới của phiên.
- `flutter run -d 12b304f9 --debug`: PASS build/cài/mở app.
- Dart Tooling Daemon hot reload: PASS; runtime error query sau lần reload đầu: none; lần reload sau bị mất kết nối và được thay bằng fresh `flutter run` thành công.
- Gửi request tạo lịch trên máy: SKIPPED vì app mở ở entry screen, state Review không được khôi phục; không gửi request hoặc dùng quota.

## Lỗi/Rủi ro

- Đã sửa: stack trace trước khi bọc lỗi, mã lỗi/count candidate an toàn, và thông báo chung che khuất lỗi thiếu catalog.
- Chưa fix được tạo lịch: catalog chưa có dữ liệu đã xác minh phù hợp với ràng buộc hiện có; không thể đánh dấu dữ liệu thiếu thành an toàn.
- Chưa xác minh: lỗi runtime từ lần chạm nút trong ảnh và backend trace, vì app hiện không giữ state Review sau khi khởi động lại.
- Cần kiểm tra tiếp: bổ sung dữ liệu có nguồn, khôi phục state onboarding đang `in_progress`, tái hiện một lần rồi xác nhận 7 ngày/35 bữa/14 hoạt động.

## Tỷ lệ hoàn thành

- Hoàn thành: diagnostics, ánh xạ lỗi, kiểm tra hồi quy và chẩn đoán cục bộ.
- Đang dở: fix dữ liệu gốc và tái hiện/lưu lịch trên thiết bị.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - không suy đoán lỗi AI/backend và giữ nguyên chặn an toàn.
- Mức độ hoàn thành task: một phần; chưa thể tạo lịch nếu thiếu bằng chứng catalog.
- Bằng chứng kiểm chứng: 26 test pass, analyzer pass, app debug chạy trên Xiaomi, số lượng SQLite tổng hợp, không có trace tạo lịch runtime.
- Điểm tốn token/chưa tối ưu: cần bảo toàn state Review qua lần dừng app để không phải tái dựng biểu mẫu thủ công.
- Cách tối ưu cho phiên sau: ưu tiên khôi phục onboarding `in_progress`, sau đó chạy một request khi candidate đã qua rà soát an toàn.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`.
