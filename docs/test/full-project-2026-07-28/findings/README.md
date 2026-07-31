# Findings — full-project-2026-07-28

Chỉ tạo finding khi đã quan sát được lỗi logic, nghiệp vụ, UI hoặc UX trong
campaign. Khi tạo README này chưa có finding nào được xác nhận.

## Tên file

```text
FND-<NNN>-<slug>.md
```

## Nội dung bắt buộc

```md
# FND-001 — <tóm tắt ngắn>

## Phân loại

- Severity: Critical | High | Medium | Low
- Loại: Logic | Nghiệp vụ | UI | UX | Bảo mật/RLS
- Phạm vi persona:
- Case liên quan:

## Môi trường

- Device/build:
- Sandbox/reset:

## Bước tái hiện

1. ...

## Kỳ vọng và thực tế

- Kỳ vọng:
- Thực tế:

## Evidence và tác động

- Assets/evidence an toàn:
- Tác động người dùng/nghiệp vụ:
- Nguyên nhân giả định (chưa xác nhận):
- Liên kết case và BD/AC/BR:
```

Không chép log thô, secret, token, mật khẩu, dữ liệu sức khỏe hoặc PII vào
finding. Một failure không có evidence đủ phải giữ ở evidence case như một
blocker/thiếu evidence, không được nâng thành finding kết luận.

