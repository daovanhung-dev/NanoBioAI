# Hướng dẫn tạo DD từ BD

## 1. Mục tiêu chuyển đổi

BD trả lời: **hệ thống phải làm gì và vì sao**.  
DD trả lời: **từng thành phần phải làm thế nào để code/test được, không cần đoán**.

## 2. Quy trình 8 bước

1. **Đóng băng nguồn BD:** gắn mã BD/version/date, không tự thay đổi ý nghĩa business rule.
2. **Tách module:** nhóm các FR theo ownership và lifecycle; ví dụ Auth, Onboarding, Profile, Notification.
3. **Tách feature:** mỗi feature phải có một outcome người dùng/technical rõ ràng.
4. **Xác định boundary:** UI, controller, repository, datasource, database, server/admin.
5. **Khai báo data contract:** input/output, persisted table/field, ownership, nullability, unique keys.
6. **Mô tả flow và state:** happy path, alternative path, failure path, route/state transition.
7. **Gắn security:** auth source, RLS, permission, secret, threat/abuse case.
8. **Viết acceptance + test:** mỗi rule quan trọng phải có ít nhất một test case traceable.

## 3. Khi nào cần tách thành file DD mới

Tách file khi một nội dung có một trong các đặc điểm:

- Có route/UI riêng hoặc controller state riêng.
- Có transaction, trigger, RLS hoặc migration riêng.
- Có failure/security policy riêng.
- Có thể code/test/review độc lập.
- Có khả năng thay đổi độc lập trong tương lai.

Không tách chỉ để tạo nhiều file; mỗi file cần coherent scope, thường 1 feature hoặc 1 cross-cutting concern.

## 4. Template mapping

| BD artifact | DD template nên dùng |
|---|---|
| Module/Scope/Actor | `DD_MODULE_TEMPLATE.md` |
| Functional requirement | `DD_FEATURE_TEMPLATE.md` |
| Hàm/use case/repository contract | `DD_FUNCTION_TEMPLATE.md` |
| Table/trigger/RLS/migration | `DD_DATABASE_TEMPLATE.md` |
| Acceptance/test | `DD_TEST_SCENARIO_TEMPLATE.md` |

## 5. Definition of Ready cho DD

Một DD chỉ là Ready for implementation khi có đủ: mục tiêu, out-of-scope, dependency, exact input/output, data ownership, security rule, happy/alternative/error flow, affected layers/files, acceptance tests và unresolved decisions được tách rõ.
