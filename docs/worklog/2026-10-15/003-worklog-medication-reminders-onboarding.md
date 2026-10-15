Commit de xuat: docs(worklog): ghi nhan nhac uong thuoc tu onboarding

# Worklog - Nhắc uống thuốc từ onboarding

## Thời gian

- Ngày: 2026-10-15
- Bắt đầu: 20:30
- Kết thúc: 21:05
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: coding + DD
- Module chính: M22 `MEDICATION_ADHERENCE`; tích hợp M01 `ONBOARDING_PROFILE` và M09 `SCHEDULE_NOTIFICATIONS`.
- Yêu cầu: cho phép nhập tên thuốc và nhiều giờ nhắc hằng ngày trong onboarding; lưu cục bộ; quản lý bật/tạm dừng, sửa giờ và xóa trong Cài đặt thông báo.
- Ranh giới: chỉ Guest/local trên thiết bị; không thêm liều dùng, lịch sử uống thuốc, tư vấn, AI, API hoặc cloud sync. Giữ nguyên hành vi loại trừ mục tiêu và tình trạng cân nặng.

## Đã làm

- Bổ sung addendum cho Advanced Health BD và DD M22 được duyệt riêng cho F01/F02 nhắc thuốc cục bộ; các phần adherence khác của M22 vẫn Draft.
- Thêm danh sách thuốc và giờ nhắc tùy chọn tại “Thông tin cần lưu ý”; mục trống không chặn onboarding, mục chưa đủ tên/giờ không lưu được; thêm lịch nhắc vào bước xem lại.
- Thêm bảng SQLite local-only và migration v33→v34; lưu lịch cùng transaction hồ sơ onboarding. Bảng không nằm trong danh sách snapshot/outbox cloud.
- Nối scheduler M09 để lập lịch hằng ngày theo múi giờ đã cấu hình; giờ trùng được gộp, refresh hủy lịch thuốc cũ trước khi lên lịch lại. Thông báo chỉ dùng nội dung chung và payload không có tên thuốc.
- Thêm màn quản lý trong Cài đặt thông báo: xem thuốc/giờ, sửa/thêm/xóa giờ, tạm dừng/bật lại và xóa lịch; lưu hướng dẫn khi quyền thông báo bị từ chối hoặc lỗi.
- Khi merge Guest đã xác nhận, chuyển owner lịch local trong cùng transaction trên thiết bị; dùng dữ liệu cloud hiện có thì không nhập lịch Guest. Thêm dấu retry để giữ quyết định chuyển lịch nếu cloud pull lỗi sau upload.
- Cập nhật registry/checklist M22, M09, version SQLite và sơ đồ cây repo.

## File code/docs đã sửa

- `docs/BD/advanced_health/BD_BioAI_Advanced_Health_Features_v1.0.md` - addendum nghiệp vụ giới hạn.
- `docs/DD/medication_adherence/` - DD M22 cho nhắc thuốc cục bộ.
- `docs/DD/schedule_notifications/Implementation_Delta_2026-10-15_M22_Medication_Reminders.md` - delta M09.
- `lib/core/storage/localdb/migrations/migration_v34.dart` và `lib/core/storage/localdb/tables/medication_reminders_table.dart` - bảng/migration SQLite.
- `lib/app_versions/v1/features/medication_reminders/` - entity, repository SQLite và provider quản lý.
- `lib/app_versions/v1/features/onboarding/` - nhập, kiểm tra, lưu và xem lại lịch thuốc; giữ nguyên nhóm loại trừ cân nặng.
- `lib/app_versions/v1/services/notifications/medication_reminder_coordinator.dart` và `notification_bootstrap.dart` - điều phối lịch M09, quyền và điều hướng.
- `lib/app_versions/v1/features/settings/` - quản lý lịch thuốc trong Cài đặt thông báo.
- `lib/app_versions/v2/features/cloud_sync/` và `lib/core/storage/localdb/app_prefs.dart` - chuyển owner local chỉ sau xác nhận merge; không mở rộng snapshot cloud.
- `test/app_versions/v1/features/medication_reminders/`, `test/core/storage/localdb/migrations/migration_v34_test.dart` và các test onboarding/cloud sync - kiểm thử tập trung.
- `docs/checklist/`, `.codex/` - cập nhật trạng thái, SQLite v34 và index.

## Commands và bằng chứng

- `flutter analyze` trên các thư mục onboarding, medication reminders, settings, notifications, localdb, cloud sync và test liên quan: PASS - không có vấn đề.
- Focused tests cho coordinator, notification navigation, Settings navigation, onboarding weight exclusivity và cloud sync contract: PASS - 26 tests.
- Onboarding completion flow và review error-message tests: PASS - 10 tests.
- `flutter test test/core/storage/localdb/migrations/migration_v34_test.dart test/app_versions/v1/features/medication_reminders/sqlite_medication_reminder_repository_test.dart test/app_versions/v1/features/onboarding/onboarding_local_datasource_test.dart test/app_versions/v2/features/cloud_sync/sqlite_user_data_sync_proof_test.dart`: BLOCKED - `sqflite_common_ffi` không nạp được `libsqlite3.so`; các assertion SQLite chưa chạy.
- `git diff --check`: PASS.
- `.codex/tools/validate_codex_integrity.ps1`: FAIL do thiếu `docs/audit/source_truth_manifest.json` và stale path trong các context/historical file không thuộc task.
- `flutter run -d linux`: không khởi chạy vì thiếu CMake. Chrome/web-server debug cũng không kết nối được debug service; CUA không có browser provider và Dart DTD không thấy app đang chạy. Hot reload, giao diện thực tế và thông báo trên thiết bị chưa xác minh.
- Không chạy Supabase, migration cloud, deploy hoặc thay đổi production.

## Lỗi/Rủi ro còn lại

- Cần chạy lại migration, lưu/mở lại SQLite, onboarding persistence và Guest merge tests trong môi trường có `libsqlite3.so`.
- Cần khởi chạy app trên môi trường có Flutter desktop/mobile hoặc Chrome debug khả dụng để hot reload và kiểm tra UI, quyền notification, lịch lặp thực tế cùng thao tác chạm.
- Validator toàn repo còn báo manifest thiếu và stale path cũ ngoài phạm vi thay đổi.

## Tỷ lệ hoàn thành

- Hoàn thành source và DD trong phạm vi M22-F01/F02.
- Chưa xác minh runtime/device và các assertion SQLite do giới hạn môi trường.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - phạm vi local-only được giữ rõ, không mở rộng cloud/schema API và không đưa tên thuốc vào thông báo.
- Mức độ hoàn thành task: implementation/DD hoàn tất; kiểm chứng SQLite và thiết bị còn pending do môi trường.
- Bằng chứng kiểm chứng: 36 focused tests không cần SQLite qua hai lượt, targeted analyzer sạch, diff check sạch; SQLite FFI và app hot reload chưa chạy được.
- Điểm tốn token/chưa tối ưu: cần xác nhận đường dẫn app/device và thư viện SQLite native sớm để dành thời gian cho kiểm thử persistence.
- Cách tối ưu cho phiên sau: kiểm tra `flutter devices`, kết nối DTD và `libsqlite3.so` trước khi chọn lệnh verify; giữ mỗi lượt phân tích/test ở đúng thư mục nguồn.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`
