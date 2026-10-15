Commit de xuat: docs(worklog): ghi nhan rang buoc lua chon onboarding

# Worklog - Ràng buộc lựa chọn đối nghịch trong onboarding

## Thời gian

- Ngày: 2026-10-15
- Bắt đầu: 20:00
- Kết thúc: 20:08
- Timezone: Asia/Saigon

## Phạm vi

- Loại task: coding
- Module chính: M01 ONBOARDING_PROFILE
- Yêu cầu gốc: Trong cùng bộ chọn, chỉ giữ một lựa chọn thuộc nhóm mục tiêu cân nặng hoặc nhóm tình trạng cân nặng đối nghịch; thay mục cũ khi chọn mục mới và giữ các mục tương thích.

## Đã làm

- Thêm loại trừ giữa `maintain_weight`, `lose_weight`, `gain_weight` trong controller; các mục tiêu khác vẫn được chọn đồng thời.
- Thêm loại trừ giữa `overweight` và `underweight`; các tình trạng khác và quy tắc `no_special_issue` vẫn được giữ.
- Bổ sung widget tests kiểm tra thay lựa chọn, giữ lựa chọn tương thích, bỏ chọn, bộ đếm và trạng thái tile.
- Không đổi schema, API hoặc dữ liệu lưu; không thêm ràng buộc giữa các bước.

## File code/docs đã sửa

- `lib/app_versions/v1/features/onboarding/presentation/controllers/onboarding_controller.dart` - thêm loại trừ cho hai nhóm lựa chọn đối nghịch.
- `test/app_versions/v1/features/onboarding/onboarding_selection_exclusivity_test.dart` - kiểm thử lựa chọn và trạng thái UI.
- `docs/worklog/2026-10-15/002-worklog-onboarding-selection-exclusivity.md` - ghi nhận phạm vi và bằng chứng.

## Tài liệu liên quan

- `docs/DD/onboarding_profile/README.md` - M01 Approved; không có câu hỏi mở cản trở quyết định người dùng đã chốt.
- `docs/checklist/checklist_complete_DD.md` - M01 Implemented; runtime và sandbox vẫn chưa được xác minh.

## Commands

- `dart format lib/app_versions/v1/features/onboarding/presentation/controllers/onboarding_controller.dart test/app_versions/v1/features/onboarding/onboarding_selection_exclusivity_test.dart`: PASS.
- `flutter test test/app_versions/v1/features/onboarding/onboarding_selection_exclusivity_test.dart test/app_versions/v1/features/onboarding/onboarding_completion_flow_test.dart`: PASS - 10 tests.
- `flutter analyze lib/app_versions/v1/features/onboarding/presentation/controllers/onboarding_controller.dart test/app_versions/v1/features/onboarding/onboarding_selection_exclusivity_test.dart`: PASS - no issues.
- `git diff --check`: PASS.
- `pwsh -NoProfile -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1`: FAIL - missing `docs/audit/source_truth_manifest.json` and stale paths in unrelated historical context files.
- DTD `hot_reload`: UNAVAILABLE - no active Flutter app was connected; DTD discovery/connection was attempted.

## Lỗi/Rủi ro

- Đã fix: lượt test ban đầu thiếu import semantics; sau đó đổi kiểm tra trạng thái sang thuộc tính `selected` của widget do finder semantics không khớp.
- Chưa fix: repository-wide context validation reports a missing source-truth manifest and stale paths in unrelated historical files; these are outside the onboarding change.
- Cần kiểm tra tiếp: hot reload và nghiệm thu trên thiết bị chưa thực hiện; không có app đang chạy để hot reload.

## Tỷ lệ hoàn thành

- Hoàn thành: 100% phần hành vi và kiểm thử được yêu cầu.
- Đang đo: hot reload/thiết bị chưa xác minh.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - chỉ ràng buộc các nhóm đối nghịch đã chốt, giữ đa lựa chọn tương thích.
- Mức độ hoàn thành task: hoàn tất phần implementation và focused verification.
- Bằng chứng kiểm chứng: 10 focused tests, targeted analyze và diff whitespace check đều PASS; repository-wide context validator has pre-existing unrelated failures.
- Điểm tốn token/chưa tối ưu: cần một lượt điều chỉnh test để dùng trạng thái widget thay cho finder semantics.
- Cách tối ưu cho phiên sau: ưu tiên assertion qua state/widget hiện có; kiểm tra DTD app availability trước khi dự kiến hot reload.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`
