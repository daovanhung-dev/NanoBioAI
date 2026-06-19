Commit de xuat: docs(worklog): ghi nhan phien create todos from issues

# Worklog - Create todos from issues

## Thoi gian
- Ngay: 2026-06-19
- Bat dau: 23:04
- Ket thuc: 23:05
- Timezone: Asia/Saigon (+07:00)

## Pham vi
- Loai task: create-todo
- Module chinh: docs/issues, docs/todo
- Yeu cau goc: doc issues va tao todo

## Da lam
- Doc 11 issue hien co trong `docs/issues`.
- Tao 11 todo rieng, moi todo link ve issue goc va tach muc tieu/file/command kiem chung.
- Khong sua code, khong chay test, khong fix issue trong phien nay.

## File code/docs da sua
- `docs/todo/ai-chat-dotenv-uninitialized/001-todo-ai-chat-dotenv-uninitialized.md` - tao - todo fix crash dotenv AI Chat.
- `docs/todo/ai-chat-unbounded-context-tokens/001-todo-ai-chat-unbounded-context-tokens.md` - tao - todo gioi han context AI Chat.
- `docs/todo/ai-raw-payload-logging/001-todo-ai-raw-payload-logging.md` - tao - todo go raw AI logging.
- `docs/todo/auth-guards-disabled/001-todo-auth-guards-disabled.md` - tao - todo bat/dong bo auth guard.
- `docs/todo/features-hub-expansion-not-wired/001-todo-features-hub-expansion-not-wired.md` - tao - todo noi route Features Hub expansion.
- `docs/todo/features-hub-widget-test-stale/001-todo-features-hub-widget-test-stale.md` - tao - todo cap nhat widget test stale.
- `docs/todo/new-care-pages-session-only-state/001-todo-new-care-pages-session-only-state.md` - tao - todo xu ly state session-only.
- `docs/todo/onboarding-sensitive-snapshot-logging/001-todo-onboarding-sensitive-snapshot-logging.md` - tao - todo go log snapshot nhay cam.
- `docs/todo/release-analyze-red-290-issues/001-todo-release-analyze-red-290-issues.md` - tao - todo xu ly analyze red.
- `docs/todo/release-format-dry-run-fails-new-pages/001-todo-release-format-dry-run-fails-new-pages.md` - tao - todo format page moi.
- `docs/todo/release-test-suite-fails/001-todo-release-test-suite-fails.md` - tao - todo xu ly test suite fail.
- `docs/worklog/2026-06-19/010-worklog-create-todos-from-issues.md` - tao - ghi nhan phien.

## Tai lieu lien quan
- [AI Chat dotenv uninitialized](../../todo/ai-chat-dotenv-uninitialized/001-todo-ai-chat-dotenv-uninitialized.md)
- [AI Chat unbounded context tokens](../../todo/ai-chat-unbounded-context-tokens/001-todo-ai-chat-unbounded-context-tokens.md)
- [AI raw payload logging](../../todo/ai-raw-payload-logging/001-todo-ai-raw-payload-logging.md)
- [Auth guards disabled](../../todo/auth-guards-disabled/001-todo-auth-guards-disabled.md)
- [Features Hub expansion not wired](../../todo/features-hub-expansion-not-wired/001-todo-features-hub-expansion-not-wired.md)
- [Features Hub widget test stale](../../todo/features-hub-widget-test-stale/001-todo-features-hub-widget-test-stale.md)
- [New care pages session-only state](../../todo/new-care-pages-session-only-state/001-todo-new-care-pages-session-only-state.md)
- [Onboarding sensitive snapshot logging](../../todo/onboarding-sensitive-snapshot-logging/001-todo-onboarding-sensitive-snapshot-logging.md)
- [Release analyze red](../../todo/release-analyze-red-290-issues/001-todo-release-analyze-red-290-issues.md)
- [Release format dry-run](../../todo/release-format-dry-run-fails-new-pages/001-todo-release-format-dry-run-fails-new-pages.md)
- [Release test suite fails](../../todo/release-test-suite-fails/001-todo-release-test-suite-fails.md)

## Commands
- `rg --files docs/issues`: PASS - liet ke 11 issue.
- `rg --files docs/todo`: PASS/SKIPPED - ban dau chua co todo de liet ke.
- `Get-Content docs/issues/...`: PASS - doc noi dung issue.
- `flutter test`: SKIPPED - mode create-todo khong test/fix.
- `flutter analyze`: SKIPPED - mode create-todo khong test/fix.

## Loi/Rui ro
- Da fix: Khong co, phien nay chi tao todo.
- Chua fix: Tat ca issue goc van con trang thai can fix.
- Can kiem tra tiep: Chon todo uu tien cao de fix theo mode `fix-issues`.
