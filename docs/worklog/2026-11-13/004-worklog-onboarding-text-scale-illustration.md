Commit de xuat: docs(worklog): ghi nhan nabi minh hoa man co chu

# Worklog - Minh họa Nabi cho màn chọn cỡ chữ

## Thời gian

- Ngày: 2026-11-13
- Bắt đầu: khoảng 13:44
- Kết thúc: 13:50
- Timezone: Asia/Bangkok

## Phạm vi

- Loại task: coding/test/docs
- Module chính: M01 `ONBOARDING_PROFILE` — màn chọn cỡ chữ
- Yêu cầu gốc: thêm hình hoặc yếu tố trực quan để màn chọn cỡ chữ bớt trống, không thêm chữ.
- Lựa chọn đã chốt: dùng ảnh Nabi căn giữa phía trên preview.

## Đã làm

- Tái sử dụng `NabiOnboardingMood.guide.assetPath`, theo asset bundle V1/V2 đang bật.
- Đặt ảnh phía trên preview, nền trong suốt, không thêm label hiển thị hay họa tiết nền.
- Dùng kích thước 112 dp ở màn thường và 88 dp khi viewport hẹp hoặc thấp.
- Mở rộng widget test để xác minh ảnh, câu preview, cập nhật cỡ chữ, responsive size và không có lỗi layout tại 390×844 / 320×640.
- Cập nhật ONB-01 screen spec, fixbug doc và M01 checklist.

## File code/docs đã sửa

- `lib/app_versions/v1/features/onboarding/presentation/pages/onboarding_text_scale_page.dart` — thêm ảnh Nabi responsive phía trên preview.
- `test/app_versions/v1/features/onboarding/onboarding_ui_simplification_test.dart` — kiểm tra ảnh hiển thị, preset text preview và viewport hẹp.
- `.codex/design/screens/onb-01-text-scale-setup.md` — cập nhật UI contract.
- `docs/fixbug/onboarding-ui-polish/001-fixbug-onboarding-ui-polish.md` — ghi follow-up minh họa.
- `docs/checklist/checklist_complete_DD.md`, `docs/checklist/checklist_task_coding.md` — bổ sung evidence M01.
- `docs/worklog/2026-11-13/004-worklog-onboarding-text-scale-illustration.md` — ghi phạm vi và kiểm chứng.

## Tài liệu liên quan

- `.codex/workflows/coding.md`
- `.codex/task-skills/coding.md`
- `.codex/domains/onboarding-profile.md`
- `.codex/design/screens/onb-01-text-scale-setup.md`
- `.codex/history/SESSION_QUALITY_REVIEW.md`

## Commands

- `dart format lib/app_versions/v1/features/onboarding/presentation/pages/onboarding_text_scale_page.dart test/app_versions/v1/features/onboarding/onboarding_ui_simplification_test.dart`: PASS.
- `dart format --set-exit-if-changed` on the same 2 files: PASS — no changes needed.
- `flutter analyze --no-pub lib/app_versions/v1/features/onboarding/presentation/pages/onboarding_text_scale_page.dart test/app_versions/v1/features/onboarding/onboarding_ui_simplification_test.dart`: PASS — no issues.
- `flutter test --no-pub --reporter expanded test/app_versions/v1/features/onboarding/onboarding_ui_simplification_test.dart`: PASS — 5 tests, including 390×844 and 320×640.
- `git diff --check`: PASS.
- `python3 .codex/tools/update_worklog_learning.py --write` / `--check`: PASS — 19 generated files current.
- PowerShell integrity validator: SKIPPED — `powershell`/`pwsh` unavailable in this Linux environment.

## Lỗi/Rủi ro

- Đã fix: vùng preview trống trải trên màn cỡ chữ; giữ nguyên chữ hiển thị, chức năng chọn và background sạch.
- Chưa fix: không có lỗi trong targeted analyzer/widget tests.
- Cần kiểm tra tiếp: Android visual/device smoke chưa chạy.

## Tỷ lệ hoàn thành

- Hoàn thành: triển khai và kiểm chứng UI trên Flutter Linux widget tests.
- Đang dở: Android/device acceptance chưa xác minh.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt — dùng asset có sẵn, tương thích asset bundle hiện hành và tránh thu hẹp preview trên màn nhỏ.
- Mức độ hoàn thành task: hoàn tất code, test và docs; chưa có device smoke.
- Bằng chứng kiểm chứng: targeted analyzer pass, 5 widget tests pass at 390×844 / 320×640, formatter pass, `git diff --check` pass, worklog history check pass.
- Điểm tốn token/chưa tối ưu: xác nhận asset minh họa trong source và mở ảnh trực tiếp để loại trừ hình có họa tiết nền không mong muốn.
- Cách tối ưu cho phiên sau: ưu tiên asset guide đã dùng trong onboarding và kiểm tra viewport ở cả chiều rộng nhỏ lẫn chiều cao thường.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`
