Commit de xuat: docs(test): ghi nhan test M32 workout-only va conflict guard

# Test — M32 workout-only và chặn xung đột lịch

## Phạm vi

Xác minh form tạo lịch tập không bị hạn chế thực phẩm chưa nhận diện chặn; request Gemini chỉ chứa dữ liệu workout; chương trình mới không sinh meals/sleep; xung đột giờ tập được phát hiện trước quota/AI và kiểm tra lại trong transaction khi áp lịch.

## Kết quả

- Trang setup ẩn các điều khiển thực đơn/giờ ngủ và cho phép nút tạo khi hồ sơ có hạn chế `động vật có vỏ` chưa ánh xạ.
- Payload Gemini không có dữ liệu allergies, recipes, meals hoặc sleep.
- Service xóa food/sleep legacy fields khỏi intake mới; validator chỉ nhận day schema workout-only. Ngày mới lưu `meals: []` và trường ngủ cũ rỗng; Program JSON cũ có meals vẫn đọc được.
- Conflict detector bắt overlap từng phần, event không có giờ kết thúc và event qua nửa đêm; bỏ qua event hoàn thành/đã qua và buổi M32 routine tương lai sẽ được thay.
- M32 meal/sleep và nguồn lịch khác vẫn được kiểm tra xung đột, không bị xóa khi áp chương trình.
- Xung đột phát sinh sau preview làm transaction rollback, giữ preview và schedule; đổi giờ rồi áp lại không gọi AI.
- Replan phát hiện conflict trước khi ghi check-in hoặc dùng quota.

## Commands

- `dart format --set-exit-if-changed <12 touched Dart files>`: PASS.
- `flutter analyze <12 touched Dart files>`: PASS, 0 issues.
- `LD_LIBRARY_PATH=/tmp/nanobio-sqlite flutter test test/app_versions/v1/features/fitness_training/fitness_training_catalog_and_validator_test.dart test/app_versions/v1/features/fitness_training/fitness_training_service_test.dart test/app_versions/v1/features/fitness_training/fitness_training_persistence_test.dart test/app_versions/v1/features/fitness_training/fitness_training_page_test.dart`: PASS, 20 tests. The temporary loader path points to the system `libsqlite3.so.0` so `sqflite_common_ffi` can run in-memory tests; no library or shim was added to the repository.
- Android QA-profile install/acceptance: NOT RUN; no disposable QA profile/device was provided. The connected personal phone was not changed or used for schedule-data inspection.
- `git diff --check`: PASS.
- `pwsh -NoProfile -File .codex/tools/validate_codex_integrity.ps1`: FAIL on repository context baseline: missing `docs/audit/source_truth_manifest.json` and stale generated-history/task-skill paths; no M32-specific failure was reported.

## Boundary

M32 remains Draft/pilot. Tech/Privacy, Clinical and QA sign-offs remain pending. These local tests do not establish Android/iOS release, live Gemini, or Supabase sandbox acceptance.
