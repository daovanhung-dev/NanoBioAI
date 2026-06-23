# 2026-06-22 — NaBi Global Assistant

## Phạm vi

- Tạo feature `features/nabi` cho nhân vật NaBi nổi toàn cục.
- Dùng Riverpod controller và resolver tập trung để biểu cảm theo ngữ cảnh.
- Dùng Canvas animation có nền trong suốt, không phụ thuộc ảnh tĩnh.
- Đưa tài liệu tích hợp ShellRoute/GoRouter và event bridge.
- Thêm unit test controller.

## Không thực hiện trong patch độc lập

- Không sửa trực tiếp route, Dashboard FAB, AIChat controller, notification callback hay `.codex` vì source project không được mount vào phiên thực thi.
- Không tự suy đoán tên file, state notifier hoặc cấu trúc route đang có của dự án.

## Files

- `lib/features/nabi/**`
- `test/features/nabi/application/nabi_controller_test.dart`
- `docs/features/11_NABI_GLOBAL_ASSISTANT.md`
