Commit de xuat: fix(m32): xin phep doi gio khi phat hien xung dot

# Worklog — M32 xin phép đổi giờ tập khi có xung đột

## Thời gian

- Ngày: 2026-10-05
- Bắt đầu: không ghi nhận riêng
- Kết thúc: 15:28
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: coding.
- Module chính: M32 FITNESS_TRAINING
- Yêu cầu: đề xuất giờ trống gần nhất khi xung đột; hỏi trước khi đổi giờ chương trình; bảo toàn hồ sơ/lịch hiện có và kiểm tra lại trong transaction lúc áp dụng.

## Đã làm

- Thêm kết quả phân tích xung đột theo giờ và truy vấn cục bộ một lần cho tám lựa chọn. Chọn giờ gần nhất còn trống trên mọi ngày tập; hòa thì giờ sớm hơn. Nếu không có giờ phù hợp, giữ nguyên lựa chọn và báo để người dùng tự điều chỉnh.
- Trước quota/AI, hiển thị giờ yêu cầu, số lịch trùng và giờ đề xuất. Chỉ sau khi đồng ý mới thử tạo; từ chối không gọi AI hoặc lưu chương trình. Giờ mới chỉ được lưu trong intake M32, không cập nhật hồ sơ cá nhân.
- Sau xem trước, thời gian hiển thị theo giờ M32 hiện chọn. Transaction vẫn chặn và rollback khi lịch đổi; UI kiểm tra lại, hỏi đồng ý cho đề xuất mới, và yêu cầu xác nhận áp dụng lần nữa. Không gọi AI khi đổi giờ của bản xem trước.
- Thêm test UI cho từ chối, đồng ý, đúng một lần gọi AI và tình huống xung đột mới lúc áp dụng cần đồng ý lại; test service cho nearest/tie/all dates/no slot; test SQLite giữ nguyên các loại lịch cũ.
- Cập nhật Review Packet, feature brief, checklist và test note; M32 vẫn Draft/pilot, reviewer sign-offs và QA acceptance vẫn Pending.
- Không đổi route hay schema SQLite v25. Không cài APK lên điện thoại hiện tại hoặc ghi vào lịch cá nhân.

## File code/docs đã sửa

- `lib/app_versions/v1/features/fitness_training/` — kết quả giờ đề xuất, truy vấn conflict cục bộ, preflight cho tạo/replan và UI consent/re-consent khi áp dụng.
- `test/app_versions/v1/features/fitness_training/` — nearest/tie/no-slot, consent, một lần AI, apply race/rollback và preservation.
- `docs/DD/fitness_training/Review_Packet.md` — yêu cầu pilot và QA về đề xuất/consent.
- `docs/DD/fitness_training/Overall.md`, `Function_List.md` — đồng bộ luồng và transaction contract.
- `docs/features/fitness-training/001-feature-fitness-training.md` — luồng người dùng và guardrails.
- `docs/test/fitness-training/003-test-workout-time-consent.md` — bằng chứng kiểm thử.
- `docs/checklist/checklist_complete_DD.md`, `docs/checklist/checklist_task_coding.md` — trạng thái 24 test và ranh giới acceptance.

## Commands

- `dart format --set-exit-if-changed <10 touched M32 Dart files>`: PASS; 0 files changed.
- `flutter analyze <10 touched M32 source/test files>`: PASS; 0 issues.
- `LD_LIBRARY_PATH=/tmp/nanobio-sqlite flutter test --concurrency=1 <4 focused M32 test files>`: PASS; 24/24. Temporary loader path targets the system SQLite shared library for in-memory FFI tests; no repository shim was added.
- `git diff --check`: PASS.
- Android QA-profile install/acceptance, live Gemini and Supabase Sandbox: NOT RUN. No APK installed and no personal schedule data read or changed in this work.

## Lỗi/Rủi ro

- Đã xử lý: người dùng phải tự đoán giờ mới khi có conflict; stale conflict lúc áp dụng không tự xin đồng ý cho giờ thay thế.
- Còn pending: M32 pilot/Draft; Tech/Privacy, Clinical và QA sign-off; Android QA với hồ sơ tổng hợp; live Gemini và Supabase Sandbox acceptance.
- Test widget ban đầu không ổn định khi tạo nhiều trang riêng trong một file; gộp luồng đồng ý/từ chối/re-consent vào fixture đã ổn định, final suite PASS.

## Tỷ lệ hoàn thành

- Hoàn thành: code, test và cập nhật tài liệu trong kế hoạch.
- Đang dở: Android QA riêng và các reviewer/release gates ngoài phạm vi source/test.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt — đề xuất giờ là quyết định tạm thời cho đúng thao tác; kiểm tra local lặp lại ở thời điểm áp dụng và chỉ thay mục tập M32 theo transaction.
- Bằng chứng: 24 focused Flutter tests, targeted analyze 0 issues, formatter sạch và `git diff --check` PASS.
- Điểm tối ưu: kiểm thử UI gộp các nhánh consent trong cùng trang để tránh lifecycle nạp catalog gây treo giữa các test widget riêng.
- Bước tiếp theo: nghiệm thu Android bằng hồ sơ QA tổng hợp, không dùng hồ sơ cá nhân.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`
