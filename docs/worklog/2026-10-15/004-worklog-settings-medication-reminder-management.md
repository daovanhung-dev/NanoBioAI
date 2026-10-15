Commit de xuat: docs(worklog): ghi nhan quan ly lich thuoc trong cai dat

# Worklog - Quản lý lịch nhắc thuốc trong Cài đặt

## Thời gian

- Ngày: 2026-10-15
- Bắt đầu: 21:05
- Kết thúc: 21:18
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: coding + docs
- Module chính: M22 `MEDICATION_ADHERENCE`; onboarding copy M01.
- Yêu cầu gốc: sau onboarding, hướng dẫn người dùng vào Cài đặt để thêm/xóa
  lịch nhắc, đổi tên thuốc và chỉnh giờ; Cài đặt phải hỗ trợ các thao tác này.
- Ranh giới: lịch nhắc thuốc tiếp tục lưu cục bộ, không thêm cloud sync/API,
  liều dùng, lịch sử đã uống hoặc tư vấn thuốc.

## Đã làm

- Bổ sung hướng dẫn ngay dưới mục lịch thuốc trong onboarding: sau khi hoàn
  tất, quản lý thêm/xóa lịch, đổi tên thuốc và giờ tại `Cài đặt > Quản lý
  thông báo > Nhắc uống thuốc`.
- Hoàn thiện khu vực Nhắc uống thuốc trong Cài đặt để thêm thuốc cùng một hay
  nhiều giờ, đổi tên thuốc, sửa/thêm giờ, tạm dừng/bật lại và xóa lịch.
- Khi tạo lịch đầu tiên từ Cài đặt, lưu lịch trước rồi xin quyền thông báo;
  từ chối quyền vẫn giữ lịch và không chặn thao tác. Các lịch tiếp theo chỉ
  đồng bộ lại lịch thông báo, không tự thay đổi lựa chọn công tắc tổng. Sau
  khi yêu cầu quyền, trạng thái công tắc Cài đặt được tải lại theo kết quả.
- Sửa trạng thái xác thực ô tên thuốc để lỗi tên trống được cập nhật khi nhập.
- Cập nhật BD/DD M22, tiêu chí chấp nhận, checklist và worklog; M22 ngoài lát
  cắt nhắc thuốc cục bộ vẫn Draft.

## File code/docs đã sửa

- `lib/app_versions/v1/features/onboarding/presentation/widgets/extras_step.dart`
  - Thêm đường dẫn Cài đặt vào phần mô tả lịch thuốc.
- `lib/app_versions/v1/features/settings/presentation/pages/notification_settings_page.dart`
  - Hỗ trợ thêm thuốc/lịch, đổi tên thuốc và diễn đạt rõ các thao tác quản lý.
- `lib/app_versions/v1/features/medication_reminders/providers/medication_reminder_settings_provider.dart`
  - Xin quyền khi tạo lịch đầu tiên từ Cài đặt; xử lý từ chối mà vẫn giữ bản ghi.
- `test/app_versions/v1/features/medication_reminders/medication_reminder_coordinator_test.dart`
  - Bổ sung hành vi repository giả cho các phương thức tạo lịch và đổi tên để
    giữ tương thích với interface; không thêm test case.
- `docs/BD/advanced_health/BD_BioAI_Advanced_Health_Features_v1.0.md` và
  `docs/DD/medication_adherence/`
  - Làm rõ quản lý sau onboarding và thêm tiêu chí Settings tạo/đổi tên.
- `docs/DD/README.md`, `docs/checklist/checklist_complete_DD.md`,
  `docs/checklist/checklist_task_coding.md`
  - Cập nhật trạng thái, bằng chứng analyze và phần còn chờ SQLite/device.

## Tài liệu liên quan

- M22 local reminder slice; M09 generic notification adapter.
- User clarification dated 2026-10-15.

## Commands

- `dart format` trên các Dart đã sửa: PASS - không còn file cần format.
- `flutter analyze` trên 5 file onboarding/Settings/provider/repository/fake:
  PASS - không có vấn đề.
- `flutter devices`: PASS - tìm thấy Linux desktop và Chrome.
- `pwsh -NoProfile -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1`:
  FAIL - thiếu `docs/audit/source_truth_manifest.json` và có stale path trong
  các tài liệu history/task-skill không thuộc phạm vi.
- `flutter run -d chrome --web-port 5020`: BLOCKED - chờ debug service, Dart
  compiler thoát bất thường; DTD không phát hiện app đang chạy.
- Dart hot reload: BLOCKED - không có Flutter app connection hoạt động.
- Focused tests: SKIPPED - không được yêu cầu.
- `git diff --check`: PASS.

## Lỗi/Rủi ro

- Đã fix: dialog đổi tên cập nhật lỗi xác thực đúng khi người dùng sửa nội dung.
- Chưa fix: validator toàn repo đang báo manifest thiếu và stale paths cũ ngoài
  phạm vi; môi trường không khởi chạy được Chrome Flutter app cho hot reload.
- Cần kiểm tra tiếp: chạy test SQLite khi có `libsqlite3.so`, rồi xác minh quyền
  và lịch nhắc hằng ngày trên app/device.

## Tỷ lệ hoàn thành

- Hoàn thành: hướng dẫn và thao tác quản lý thuốc/lịch trong Cài đặt được nối
  tới repository local; targeted analyzer pass.
- Đang đo: runtime/UI, SQLite FFI và notification delivery trên thiết bị.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - hướng dẫn trỏ tới đúng màn hình và Settings cung cấp
  thao tác thêm, đổi tên, sửa giờ, tạm dừng, bật lại và xóa.
- Mức độ hoàn thành task: hoàn tất source/docs theo yêu cầu; runtime chưa xác minh.
- Bằng chứng kiểm chứng: targeted analyzer pass; hot reload không thể chạy do
  không có app connection; validator fail vì lỗi tài liệu ngoài phạm vi.
- Điểm tốn token/chưa tối ưu: lượt thử Chrome mất thời gian chờ debug service.
- Cách tối ưu cho phiên sau: kiểm tra DTD connection trước khi khởi chạy Flutter
  web; tiếp tục xác minh persistence khi có SQLite native library.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`
