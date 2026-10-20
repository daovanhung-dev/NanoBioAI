Commit de xuat: docs(worklog): ghi nhan ra soat luong tao lich moi

# Worklog - Rà soát luồng tạo lịch trình mới

## Thời gian

- Ngày: 2026-10-18
- Bắt đầu: 15:50 Asia/Ho_Chi_Minh
- Kết thúc: 15:55 Asia/Ho_Chi_Minh
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: find-issues / review source hiện tại
- Module chính: M02 personal schedule, meal plan và lifestyle schedule
- Yêu cầu gốc: Nhận xét luồng hoạt động hiện tại của tạo lịch trình mới

## Đã làm

- Nạp project router, workflow, task-skill và hai domain AI/lifestyle schedule.
- Lần theo CTA tạo lịch kế tiếp, auth/quota, đọc horizon, sinh meal/exercise theo ngày, validate, lưu SQLite, refresh provider, notification và reward eligibility.
- Ghi nhận hai vấn đề có bằng chứng source: retry bị chặn sau khi đã ghi lịch một phần; copy success của fallback chưa nói rõ model local và giới hạn tạo lại.

## File code/docs đã sửa

- Không sửa runtime code.
- Tạo `docs/issues/personal-schedule-partial-generation-resume/001-issue-personal-schedule-partial-generation-resume.md`.
- Tạo `docs/issues/personal-schedule-fallback-copy/001-issue-personal-schedule-fallback-copy.md`.
- Tạo worklog này và refresh history/task-skill sinh tự động.

## Tài liệu liên quan

- `.codex/AGENTS.md`, `.codex/PROJECT_MAP.md`
- `.codex/workflows/find-issues.md`, `.codex/task-skills/find-issues.md`
- `.codex/domains/lifestyle-schedule.md`, `.codex/domains/ai-service.md`

## Commands

- Đọc source có chọn lọc bằng Python `pathlib` và `sed`: PASS - đã truy dấu nhánh UI, service, staging và SQLite.
- Test/build/device QA: SKIPPED - yêu cầu là nhận xét luồng; chưa xác minh động.
- `python3 .codex/tools/update_worklog_learning.py --write`: chạy sau khi ghi worklog.
- Diff whitespace check: sẽ chạy cho issue/worklog mới sau refresh.

## Lỗi/Rủi ro

- Đã xác nhận từ source: service kiểm tra horizon trước khi tìm request chưa hoàn tất; request store lại lưu từng ngày vào bảng lịch chính.
- Chưa xác minh trên thiết bị: tần suất thực tế xảy ra lỗi giữa các ngày và cách snackbar/horizon hiển thị theo thời gian.
- Cần kiểm tra tiếp: thử nghiệm resume sau lỗi giữa chừng và nội dung fallback trên thiết bị Android có model local.

## Tỷ lệ hoàn thành

- Hoàn thành: đọc và đánh giá source hiện tại; lập hai issue docs kèm bằng chứng.
- Đang dở: chưa chạy test, build hoặc QA thiết bị; chưa sửa các phát hiện.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - phân biệt luồng member tạo lịch tiếp theo với fallback và lưu từng ngày; giới hạn xác minh được ghi rõ.
- Mức độ hoàn thành task: hoàn thành nhận xét source và ghi nhận rủi ro; không sửa runtime theo phạm vi.
- Bằng chứng kiểm chứng: thứ tự guard/request lookup và transaction lưu ngày được đọc trực tiếp; chưa có test động.
- Điểm tốn token/chưa tối ưu: lần đầu gọi `rg` không khả dụng trong shell, sau đó chuyển sang Python tìm source.
- Cách tối ưu cho phiên sau: dùng Python `pathlib` làm fallback tìm kiếm trên môi trường không cài ripgrep; chạy focused test chỉ khi được yêu cầu sửa/xác minh.
- Task-skill cần đọc lần sau: `.codex/task-skills/find-issues.md`
