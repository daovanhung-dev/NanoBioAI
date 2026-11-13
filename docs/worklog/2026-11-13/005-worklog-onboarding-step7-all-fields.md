# Worklog - Onboarding Step 7 hỏi đủ thông tin lịch sinh hoạt

## Thời gian

- Ngày: 2026-11-13
- Timezone: Asia/Bangkok

## Phạm vi

- Loại task: coding/test/docs
- Module chính: M01 `ONBOARDING_PROFILE` — bước lịch sinh hoạt
- Yêu cầu: hỏi đủ các thông tin lịch đang lưu cho ngày thường/cuối tuần và thêm minh họa Nabi để cân bố cục.
- Ranh giới: giữ entity, validator, xác nhận routine, API/schema và persistence hiện có.

## Đã làm

- Thay phần mở rộng tùy chọn sau 14 câu giờ chính bằng một luồng tuần tự cho cả hai hồ sơ.
- Hỏi giờ thức dậy, giờ của 5 bữa, giờ ngủ, ngủ trưa Có/Không và giờ bắt đầu/kết thúc khi Có, hai khung tập, giờ bận Có/Không và khung giờ khi Có.
- Hiển thị ảnh Nabi ở mọi câu; ảnh 96 dp ở kích thước thường và 72 dp trên màn hẹp/thấp. Khung giờ có hai nút chọn giờ độc lập.
- Duy trì progress theo số câu áp dụng của hồ sơ hiện tại, CTA “Xác nhận” ở câu cuối, validation hiện có và back theo từng câu.
- Bỏ tùy biến `showCoreTimes` không còn được dùng trong editor lịch sinh hoạt.
- Cập nhật screen spec, checklist M01 và fixbug doc để phản ánh luồng mới.
- Thêm widget test cho đủ trường ở hai hồ sơ, các nhánh bật/tắt ngủ trưa/giờ bận, back/system back và bố cục 320×640.

## File đã sửa

- `lib/app_versions/v1/features/onboarding/presentation/widgets/daily_routine_step.dart`
- `lib/app_versions/v1/features/onboarding/presentation/controllers/onboarding_controller.dart`
- `lib/app_versions/v1/features/daily_routine/presentation/widgets/daily_routine_preferences_editor.dart`
- `test/app_versions/v1/features/onboarding/onboarding_ui_simplification_test.dart`
- `.codex/design/screens/onb-08-daily-routine-step.md`
- `docs/checklist/checklist_complete_DD.md`
- `docs/checklist/checklist_task_coding.md`
- `docs/fixbug/onboarding-ui-polish/001-fixbug-onboarding-ui-polish.md`
- `docs/worklog/2026-11-13/005-worklog-onboarding-step7-all-fields.md`

## Commands và kết quả

- `dart format` trên 4 file Dart đã sửa: PASS.
- `dart format --set-exit-if-changed` trên 4 file Dart: PASS — không còn file cần format.
- `flutter analyze --no-pub` trên 4 file Dart: PASS — không có issue.
- `flutter test --no-pub --reporter expanded test/app_versions/v1/features/onboarding/onboarding_ui_simplification_test.dart`: PASS — 7 widget tests.
- `git diff --check`: PASS.
- `python3 .codex/tools/update_worklog_learning.py --write`: PASS — cập nhật 19 file history/task-skill sinh tự động.
- `python3 .codex/tools/update_worklog_learning.py --check`: PASS — 19 file sinh tự động hiện hành.
- `.codex/tools/validate_codex_integrity.ps1`: SKIPPED — host Linux không có `powershell`/`pwsh`.
- Android visual/device smoke: chưa chạy; bằng chứng hiện tại là Flutter Linux widget tests.

## Lỗi, giới hạn và acceptance còn thiếu

- Không phát hiện lỗi trong targeted analyzer hoặc widget suite.
- Chưa xác minh giao diện thực tế trên Android; M01 device acceptance không thay đổi.
- Test xác nhận các nút giờ bắt đầu/kết thúc hiển thị và responsive; chưa chạy thao tác chọn giờ trên thiết bị thật.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt — mọi trường trong entity được hỏi, nhánh điều kiện không làm lệch câu hiện tại, hình Nabi xuất hiện xuyên suốt và giữ nguyên data contract.
- Mức độ hoàn thành task: hoàn tất source, UI tests và tài liệu; Android visual/device smoke chưa xác minh.
- Bằng chứng kiểm chứng: 7 widget tests, targeted analyzer, formatter và `git diff --check` pass.
- Điểm tốn token/chưa tối ưu: kiểm tra lại mô tả cũ trong checklist mất thêm một lượt vì hai checklist có cấu trúc khác nhau.
- Cách tối ưu cho phiên sau: tìm chuỗi section bằng `rg -n -A` trong đúng tài liệu trước khi sửa.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`
