# DEV_WORKFLOW

## Quy trình dev chuẩn

1. Intake: hiểu task, module, ràng buộc.
2. Discover: đọc `.codex/PROJECT_MAP.md`, chọn đúng playbook, dùng `rg` tìm usage.
3. Plan: viết plan 3–5 ý, không quá dài.
4. Patch: sửa nhỏ nhất đủ đúng lỗi gốc.
5. Validate: chạy quick/full check.
6. Report: báo file sửa, test, rủi ro.

## Luật sửa code

- Không sửa lan man ngoài phạm vi task.
- Không đổi kiến trúc chỉ vì tiện.
- Không đưa mock/fake data vào production.
- Không hard-code key, user id, path máy local.
- Không dùng `dynamic`, `!`, nullable workaround nếu chưa có lý do rõ.
- Nếu đổi public API, phải `rg` toàn bộ usage trước.
- Nếu thêm model/table/DAO, phải đồng bộ naming và serialization.

## Definition of Done

Task chỉ hoàn thành khi:

- Code compile/analyze sạch.
- Test liên quan pass hoặc có lý do rõ vì sao chưa chạy được.
- Không làm hỏng luồng onboarding -> schedule -> dashboard -> notification.
- Báo cáo cuối task rõ ràng.
