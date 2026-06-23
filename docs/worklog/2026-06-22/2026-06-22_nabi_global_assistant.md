# 2026-06-22 — Nabi Global Assistant

## Phạm vi

- Tạo feature `features/Nabi` cho nhân vật Nabi nổi toàn cục.
- Dùng Riverpod controller và resolver tập trung để biểu cảm theo ngữ cảnh.
- Dùng Canvas animation có nền trong suốt, không phụ thuộc ảnh tĩnh.
- Đưa tài liệu tích hợp ShellRoute/GoRouter và event bridge.
- Thêm unit test controller.

## Không thực hiện trong patch độc lập

- Không sửa trực tiếp route, Dashboard FAB, AIChat controller, notification callback hay `.codex` vì source project không được mount vào phiên thực thi.
- Không tự suy đoán tên file, state notifier hoặc cấu trúc route đang có của dự án.

## Files

- `lib/features/Nabi/**`
- `test/features/Nabi/application/Nabi_controller_test.dart`
- `docs/features/11_Nabi_GLOBAL_ASSISTANT.md`
