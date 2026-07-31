# Case evidence — full-project-2026-07-28

Tạo một file `<CASE-ID>.md` tại đây sau khi case tương ứng được chạy. Không tạo
file hàng loạt trước khi có kết quả thật.

```md
---
case_id: <CASE-ID>
status: <PASS|FAIL|N/A|GAP|BLOCKED>
command_id: <CMD-ID>
actual_result: "<tóm tắt đã redact>"
artifacts:
  - ../assets/<CASE-ID>--<state>--<timestamp>.png
# rationale: "Bắt buộc khi status là N/A hoặc GAP."
---

# <CASE-ID> — <tên case>

## Phạm vi

- Persona:
- BD / AC / BR:
- Device/build:
- Sandbox/app-data reset:

## Precondition và bước chạy

1. ...

## Kỳ vọng và thực tế

- Kỳ vọng:
- Thực tế:

## Evidence

- Screenshot/technical evidence:
- Finding liên quan (nếu có):
```

`N/A` và `GAP` phải nêu rationale có thể kiểm chứng; `FAIL` phải liên kết một
finding nếu lỗi đã được xác nhận. Không lưu dữ liệu nhạy cảm trong case record.

