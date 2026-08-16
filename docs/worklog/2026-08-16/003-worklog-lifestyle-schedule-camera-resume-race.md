# Worklog - Fix Lifestyle Schedule camera resume race

- Date: 2026-08-16
- Workflow: `.codex/workflows/bugfix.md`
- Task skill: `.codex/task-skills/bugfix.md`
- Domain: `.codex/domains/lifestyle-schedule.md`

## Scope

Fix trạng thái lịch trình không đồng bộ sau khi chụp ảnh minh chứng: SQLite có thể đã completed nhưng Riverpod/UI vẫn giữ snapshot pending và lần thao tác tiếp theo báo `alreadyCompleted`.

## Root cause evidence

- `LifestyleSchedulePage.didChangeAppLifecycleState(resumed)` luôn chạy `refresh()` + `reconcilePendingRewards()`.
- System camera phát `resumed` trước khi `toggleItem()` kết thúc.
- `toggleItem()` trước đây cập nhật summary dựa trên `current` snapshot lấy trước camera.
- Local datasource ném `ScheduleCompletionErrorCode.alreadyCompleted` nếu SQLite đã completed.

## Changes

1. Thêm `hasActiveCompletionFlow` trên controller.
2. Chặn lifecycle refresh/reconcile trong khi completion active.
3. Chặn `refresh()`/`reconcilePendingRewards()` ở controller để bảo vệ mọi caller.
4. Reload summary + proofs từ repository sau local commit.
5. Xử lý `alreadyCompleted` như idempotent success và dọn proof mới chưa commit.
6. Bổ sung regression tests cho:
   - refresh trong lúc camera active;
   - authoritative state sau completion có `1/11`;
   - stale pending UI + SQLite completed không còn tạo error banner.

## Validation

- Static source checks: completed.
- Dart/Flutter formatter/analyzer/tests: chưa chạy trong môi trường hiện tại vì không có Dart/Flutter SDK.
- Package integrity và secret scan: chạy trước khi bàn giao.

## Self-review

- Không đổi completion window 30 phút.
- Không thay schema SQLite/Supabase.
- Không thêm client-side reward increment.
- Patch giới hạn ở lifecycle/completion state consistency và focused tests/docs.
