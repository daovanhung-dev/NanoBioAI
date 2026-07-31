# Technical evidence — full-project-2026-07-28

Lưu các tóm tắt kỹ thuật tối thiểu, đã redact, dùng để bổ trợ cho case RLS,
race, idempotency, ledger, retry, Storage hoặc backend. Khi tạo README này
chưa có technical evidence nào.

## Quy tắc

- Tạo một file `<CASE-ID>--safe-summary.md` chỉ sau khi chạy case tương ứng.
- Chỉ ghi command ID, actor alias, assertion, outcome, reset/build/device và
  reference artifact đã được redact. Không chép raw SQL result, JWT, token,
  password, email fixture, object path, health proof hoặc payload/log thô.
- Two-client/concurrency phải ghi rõ session độc lập, thứ tự thao tác và
  assertion idempotency; một ảnh kết quả mới trên thiết bị thật vẫn cần được
  liên kết từ evidence case khi có bề mặt UI.
- File này không thay thế `cases/<CASE-ID>.md`; nó là artifact được trỏ từ YAML
  front matter của case.

