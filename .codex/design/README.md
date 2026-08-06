# .codex/design — Nabi Kinetic Aura

Thư mục này là nguồn thiết kế canonical cho đợt refactor toàn bộ presentation layer NanoBio.
Tài liệu được tạo từ static audit snapshot `nano_app(8)` ngày 2026-08-05.

## Phạm vi đã audit

- `183` file UI/theme/router/app-shell.
- `46` page/screen.
- `59` widget file.
- `40` file đang có animation/motion.
- `21` file dùng `Duration(milliseconds: ...)` trực tiếp.
- `33` file dùng `Color(0x...)` hoặc `Colors.*` trực tiếp.
- `11` file gọi haptic trực tiếp.
- `0` file có playback sound trong source hiện tại.

## Thứ tự đọc

1. [`00_NABI_KINETIC_AURA_MASTER_DESIGN.md`](00_NABI_KINETIC_AURA_MASTER_DESIGN.md)
2. [`02_COLOR_LIGHT_DEPTH_SYSTEM.md`](02_COLOR_LIGHT_DEPTH_SYSTEM.md)
3. [`03_MOTION_SYSTEM.md`](03_MOTION_SYSTEM.md)
4. [`04_MICRO_INTERACTIONS.md`](04_MICRO_INTERACTIONS.md)
5. [`05_SOUND_HAPTIC_SYSTEM.md`](05_SOUND_HAPTIC_SYSTEM.md)
6. [`06_COMPONENT_DESIGN_SYSTEM.md`](06_COMPONENT_DESIGN_SYSTEM.md)
7. [`12_UI_FILE_DESIGN_MATRIX.md`](12_UI_FILE_DESIGN_MATRIX.md)
8. Group file tương ứng trong [`groups/`](groups/)
9. [`15_CODING_PLAN.md`](15_CODING_PLAN.md)
10. [`16_ACCEPTANCE_CHECKLIST.md`](16_ACCEPTANCE_CHECKLIST.md)
11. [`18_MOTION_FEEDBACK_DEBT_REGISTER.md`](18_MOTION_FEEDBACK_DEBT_REGISTER.md)
12. [`19_PROTOTYPE_SPEC.md`](19_PROTOTYPE_SPEC.md)
13. [`20_CODING_WAVE_FILE_MANIFEST.md`](20_CODING_WAVE_FILE_MANIFEST.md)

## Nguồn sự thật

- Thiết kế: thư mục này.
- Runtime và nghiệp vụ: source/test hiện tại.
- Token/component hiện hữu: `lib/core/theme/`.
- Quyền, membership, quota, Sale và Admin: trusted backend/Supabase; animation không được mở quyền.

## Trạng thái

- Design/audit: **Complete ở mức static source**.
- Prototype trực quan/âm thanh: **Chưa thực hiện**.
- Coding: **Chưa thực hiện**.
- Flutter analyze/test/device visual QA: **Chưa thực hiện trong phiên design**.
