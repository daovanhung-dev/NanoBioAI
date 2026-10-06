Commit de xuat: fix(m31): ghi nhan contact priority load race

# Worklog — M31 thêm liên hệ trước khi tải xong danh sách

## Thời gian

- Ngày: 2026-10-06
- Bắt đầu: khoảng 13:24
- Kết thúc: 13:44
- Timezone: Asia/Saigon

## Phạm vi

- Loại task: bugfix
- Module chính: M31 SLEEP_SAFETY_MONITORING
- Yêu cầu gốc: tái hiện và sửa lỗi không thêm được SafetyContact vào danh sách.

## Đã làm

- Tái hiện race cục bộ: khi lần tải contact đầu bị giữ, thao tác lưu dùng ưu tiên
  mặc định 1 dù đã có contact ưu tiên 1; fake RPC mô phỏng unique conflict.
- Controller đợi danh sách tải trước khi chọn ưu tiên; trang hiện tiến trình tải
  và không cho mở form trước khi sẵn sàng.
- Kiểm tra read-only project NanoBio: APK và cấu hình app khớp project liên kết;
  hai migration M31 hiện trong remote history; rollout core bật, phone/Zalo tắt.
- Không tạo contact QA, OTP, cuộc gọi, hay thay đổi dữ liệu staging/production.

## File code/docs đã sửa

- `lib/app_versions/v1/features/sleep_tracking/providers/sleep_safety_controller.dart` — đánh dấu danh sách đã tải và chờ dữ liệu trước khi tính ưu tiên.
- `lib/app_versions/v1/features/sleep_tracking/presentation/pages/sleep_safety_contacts_page.dart` — trạng thái tải và khóa nút thêm trước khi có dữ liệu.
- `test/app_versions/v1/features/sleep_tracking/providers/sleep_safety_controller_test.dart` — regression test cho fetch chậm và priority conflict.
- `docs/fixbug/sleep-safety-contact/002-fixbug-contact-load-priority-race.md` — ghi nhận triệu chứng, nguyên nhân và bằng chứng.
- `docs/checklist/checklist_complete_DD.md`, `docs/checklist/checklist_task_coding.md` — cập nhật trạng thái M31 và handoff.

## Tài liệu liên quan

- `docs/DD/sleep_safety_monitoring/README.md`
- `docs/BD/sleep_safety/BD_NanoBio_Sleep_Safety_M31_v1.2.md`
- `docs/worklog/2026-10-06/001-worklog-m31-zalo-phone-fallback.md`

## Commands

- Regression test trước sửa: FAIL đúng dự kiến với `sleep_safety_contact_priority_conflict`.
- Focused M31 Flutter tests (5 files, có `LD_LIBRARY_PATH` trỏ symlink SQLite tạm): PASS 22/22.
- Targeted `flutter analyze` trên controller, page và test: PASS, 0 issue.
- `git diff --check`: PASS.
- `validate_codex_integrity.ps1`: FAIL vì thiếu
  `docs/audit/source_truth_manifest.json` và một số đường dẫn lịch sử trong
  task-skill/worklog đã stale; không thuộc phạm vi bugfix nên được giữ nguyên.
- Android QA contact save: chưa chạy; `adb shell input tap` bị hệ điều hành chặn do thiếu `INJECT_EVENTS`.

## Lỗi/Rủi ro

- Đã fix: submit trước khi load danh sách có thể chọn trùng mức ưu tiên đang tồn tại.
- Chưa xác minh: lưu contact trên Android UI thực tế; không có bản ghi QA nào được tạo.
- Cần kiểm tra tiếp: người vận hành thao tác UI trên QA account sau khi build/app source mới được đưa lên thiết bị.

## Tỷ lệ hoàn thành

- Hoàn thành: source fix và regression cục bộ.
- Đang dở: nghiệm thu thao tác trên thiết bị Android.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt; race được tái hiện trước khi sửa và regression xác nhận sau sửa.
- Mức độ hoàn thành task: source bugfix hoàn tất; nghiệm thu thiết bị còn mở do quyền input.
- Bằng chứng kiểm chứng: regression đỏ/xanh, 22 focused tests, targeted analyzer sạch; project/migrations/flags đã đọc.
- Điểm tốn token/chưa tối ưu: không thể chạm UI do `INJECT_EVENTS`; full app-device flow vẫn cần người vận hành.
- Cách tối ưu cho phiên sau: dùng QA thao tác UI trực tiếp; Codex tiếp tục đọc trạng thái bằng ADB, không chạy integration runner.
- Task-skill cần đọc lần sau: `.codex/task-skills/bugfix.md`.
