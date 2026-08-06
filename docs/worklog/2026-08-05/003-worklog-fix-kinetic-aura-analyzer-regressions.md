Commit de xuat: fix(ui): dọn analyzer regression sau Nabi Kinetic Aura

# Worklog - Fix analyzer regressions sau Nabi Kinetic Aura

## Thời gian

- Ngày: 2026-08-05
- Bắt đầu: 22:10
- Kết thúc: 22:20
- Timezone: Asia/Saigon (UTC+07:00)

## Phạm vi

- Loại task: bugfix
- Workflow: `.codex/workflows/bugfix.md`
- Task skill: `.codex/task-skills/bugfix.md`
- Module chính: UI/theme/motion/feedback/Nabi
- Yêu cầu gốc: sửa danh sách diagnostics Dart Analyzer sau khi triển khai Nabi Kinetic Aura.

## Invariants đã giữ

- Không thay đổi business logic, SQLite, Supabase, quota hoặc access policy.
- Không đổi API repository/datasource.
- Feedback success vẫn chỉ phát sau kết quả thật.
- Không thêm dependency hoặc production mock data.

## Đã làm

- Dọn toàn bộ import thừa được analyzer liệt kê.
- Sửa named parameter của `AppPressScale` từ `scale` sang `pressedScale`.
- Bổ sung alias `AppDuration.emphasized` từ canonical motion foundation.
- Sử dụng kết quả `ref.refresh` trong FamilyPlus và ánh xạ trạng thái `failure` thành error feedback.
- Loại bỏ import token không dùng ở `SectionHeader`.
- Dọn interpolation braces không cần thiết.
- Dọn import `sqflite` trùng trong test FFI.
- Chuyển semantics contract test sang `flagsCollection.isSelected.toBoolOrNull()`.
- Loại bỏ marker `TODO` trong `AdminLogger.exportLogs` và mô tả đúng trust boundary.
- Chuẩn hóa lại indentation của FamilyPlus error state.

## File code/docs đã sửa

- 21 file Dart theo danh sách trong `docs/fixbug/kinetic-aura-analyzer-regressions/001-fixbug-kinetic-aura-analyzer-regressions.md`.
- `docs/fixbug/kinetic-aura-analyzer-regressions/001-fixbug-kinetic-aura-analyzer-regressions.md` - tạo - ghi nhận nguyên nhân và bản vá.
- `docs/worklog/2026-08-05/003-worklog-fix-kinetic-aura-analyzer-regressions.md` - tạo - ghi nhận phiên.

## Tài liệu liên quan

- `.codex/design/00_NABI_KINETIC_AURA_MASTER_DESIGN.md`
- `.codex/design/15_CODING_PLAN.md`
- `.codex/domains/ui-nami.md`

## Commands

- Targeted Python static validator: PASS - 21 Dart files, delimiter, import resolution, targeted diagnostic patterns và trailing whitespace.
- `rg` targeted diagnostics: PASS - không còn import/pattern lỗi đã báo.
- `python tools/validate_kinetic_aura.py`: chạy sau khi cập nhật docs.
- `dart format`: SKIPPED - không có Dart executable.
- `flutter analyze`: SKIPPED - không có Flutter SDK.
- `flutter test`: SKIPPED - không có Flutter SDK.
- PowerShell history refresh: SKIPPED - không có PowerShell.

## Lỗi/Rủi ro

- Đã fix: toàn bộ diagnostics người dùng cung cấp.
- Chưa fix: không ghi nhận lỗi ngoài danh sách trong workflow này.
- Cần kiểm tra tiếp: chạy targeted format/analyze/test trên máy phát triển.

## Tỷ lệ hoàn thành

- Hoàn thành: 100% bản vá source theo danh sách diagnostics.
- Đang dở: runtime/analyzer certification trên Flutter SDK thật.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - bản vá nhỏ, giữ compatibility và không refactor ngoài phạm vi.
- Mức độ hoàn thành task: hoàn thành source patch và tài liệu; thiếu Flutter analyzer evidence do toolchain không có.
- Bằng chứng kiểm chứng: targeted validator PASS, import resolution PASS, exact diagnostic pattern checks PASS.
- Điểm tốn token/chưa tối ưu: danh sách lỗi trải rộng nhiều file nhưng phần lớn là lint; lần sau có thể chạy script mapping diagnostic → patch trực tiếp sớm hơn.
- Cách tối ưu cho phiên sau: chạy `dart format`, targeted `flutter analyze` và bốn test liên quan ngay trên máy có Flutter SDK.
- Task-skill cần đọc lần sau: `.codex/task-skills/bugfix.md`
