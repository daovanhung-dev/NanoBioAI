Commit de xuat: fix(m32): gioi han lich tap va chan xung dot lich

# Worklog — M32 workout-only conflict guard

## Thời gian

- Ngày: 2026-10-05
- Bắt đầu: Không ghi nhận chính xác; tiếp tục từ context M32 đã nạp.
- Kết thúc: 14:37 Asia/Ho_Chi_Minh.
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: fix / coding / test / cập nhật DD và worklog.
- Module chính: M32 FITNESS_TRAINING.
- Yêu cầu gốc: tạo mới lịch tập dù hồ sơ có dị ứng chưa nhận diện; tránh chồng lấn; không xóa các mục lịch khác; giữ dữ liệu cá nhân trên điện thoại nguyên trạng.

## Đã làm

- Chuyển M32 sang luồng workout-only: bỏ dị ứng/thực đơn/giờ ngủ khỏi điều kiện tạo, payload Gemini và validator. Program day mới lưu `meals: []` và chuỗi ngủ rỗng; parser vẫn tương thích program cũ.
- Sanitize cả legacy food/sleep fields khi service lưu intake cho preview mới; không chỉ loại chúng khỏi payload gửi AI.
- Thêm conflict detector theo khoảng thời gian, xét event chỉ có giờ bắt đầu, overnight, completed/past; bỏ qua future incomplete M32 `routine` sẽ được thay.
- Kiểm tra conflict trước quota/AI cho tạo mới và replan. Replan không còn ghi check-in vào program đang active trước khi có kết quả.
- Kiểm tra lại conflict trong transaction khi confirm. Khi xung đột transaction rollback trước mọi mutation; khi thành công chỉ thay future incomplete M32 `routine`, giữ M32 meal/sleep, lịch sức khỏe, lịch khác, completed và past.
- Cho đổi giờ ở preview/replan conflict để thử lại mà không gọi AI lần nữa; hiển thị ngày/giờ và tên mục đang xung đột.
- Cập nhật M32 Overall, Function List, feature brief, review packet và checklist; giữ Draft/pilot và toàn bộ sign-off ở Pending.
- Không đổi schema SQLite v25, route hay dữ liệu trên điện thoại hiện tại.

## File code/docs đã sửa

- `lib/app_versions/v1/features/fitness_training/` — intake, AI prompt/validator, repository contract, transaction apply, overlap detection và UI.
- `test/app_versions/v1/features/fitness_training/` — workout-only payload/validator, UI blocker, SQLite overlap/rollback/preservation và retry tests.
- `docs/DD/fitness_training/Overall.md`, `Function_List.md`, `Review_Packet.md` — cập nhật contract pilot.
- `docs/features/fitness-training/001-feature-fitness-training.md` — cập nhật phạm vi và flow.
- `docs/test/fitness-training/002-test-workout-only-conflict-guard.md` — kết quả kiểm thử tập trung.
- `docs/checklist/checklist_complete_DD.md`, `checklist_task_coding.md` — trạng thái bằng chứng, không nâng release readiness.
- `.codex/history/*`, `.codex/task-skills/*` — làm mới từ worklog bằng script dự án.

## Tài liệu liên quan

- `docs/DD/fitness_training/Review_Packet.md` — reviewer Tech/Privacy, Clinical, QA vẫn Pending.
- `docs/DD/fitness_training/Overall.md` — contract workout-only và conflict guard.
- `docs/test/fitness-training/002-test-workout-only-conflict-guard.md` — bằng chứng test mới.

## Commands

- `dart format <12 touched Dart files>`: PASS.
- `dart format --set-exit-if-changed <12 touched Dart files>`: PASS, không file nào cần format.
- `flutter analyze <12 touched Dart files>`: PASS, 0 issues.
- `LD_LIBRARY_PATH=/tmp/nanobio-sqlite flutter test <4 focused M32 test files>`: PASS, 20/20. Temporary symlink targets system `libsqlite3.so.0` for in-memory FFI tests; repository unchanged by the shim.
- `git diff --check`: PASS.
- `pwsh -NoProfile -File .codex/tools/validate_codex_integrity.ps1`: FAIL on repository context baseline: missing `docs/audit/source_truth_manifest.json` and stale generated-history/task-skill paths; no M32-specific failure was reported.
- `python3 .codex/tools/update_worklog_learning.py --check`: PASS after worklog/history refresh.
- Android QA profile/device, live Gemini and Supabase sandbox: SKIPPED; no disposable QA profile/device requested or available. Connected personal phone was not inspected or modified this turn.

## Lỗi/Rủi ro

- Đã fix: food restriction chưa nhận diện không khóa tạo lịch tập; request không gửi dữ liệu food/sleep; lịch ăn/ngủ M32 không bị xóa; chặn overlap cả lúc preflight và apply.
- Chưa fix: M32 vẫn là pilot/Draft; reviewer approvals, Android/iOS QA, sandbox/RLS, live Gemini và nội dung lâm sàng còn pending.
- Cần kiểm tra tiếp: cài đặt và xác nhận trên hồ sơ QA rời; không dùng hồ sơ cá nhân hiện tại.

## Tỷ lệ hoàn thành

- Hoàn thành: phần code/test/docs trong kế hoạch workout-only và conflict guard.
- Đang dở: Android QA-profile acceptance và các reviewer/release gates ngoài phạm vi source/test.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt — conflict được kiểm tra ở hai thời điểm; transaction không mutate trước guard; test bao phủ bảo toàn lịch.
- Mức độ hoàn thành task: implementation và targeted local verification hoàn tất; device acceptance còn chờ hồ sơ QA riêng.
- Bằng chứng kiểm chứng: 20 focused Flutter tests, 0 targeted analyzer issues, formatter sạch; SQLite in-memory chạy qua host loader shim.
- Điểm tốn token/chưa tối ưu: test host thiếu symlink `libsqlite3.so`; phát hiện native `.so.0` sẵn có và dùng loader path tạm, không cài package mới.
- Cách tối ưu cho phiên sau: chuẩn bị disposable QA profile/device trước khi chạy native acceptance; tiếp tục tách local test proof khỏi release proof.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`
