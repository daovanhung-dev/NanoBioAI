Commit de xuat: docs(worklog): ghi nhan tao checklist issue todo

# Worklog - Tao checklist issue todo

## Thoi gian
- Ngay: 2026-06-19
- Bat dau: 23:50
- Ket thuc: 23:52
- Timezone: Asia/Saigon (+07:00)

## Pham vi
- Loai task: docs
- Module chinh: docs/issues, docs/todo
- Yeu cau goc: tao checklist cho todo va issues

## Da lam
- Kiem ke 11 issue trong `docs/issues`.
- Kiem ke 11 todo trong `docs/todo`.
- Ghi nhan 1 todo da done va 1 fixbug da co cho AI Chat dotenv.
- Tao checklist tracker tong hop trang thai issue/todo/fixbug.

## File code/docs da sua
- `docs/todo/issue-todo-checklist/001-todo-issue-todo-checklist.md` - tao - checklist tong hop issue/todo.
- `docs/worklog/2026-06-19/012-worklog-issue-todo-checklist.md` - tao - ghi nhan phien docs.

## Tai lieu lien quan
- [Checklist issue todo](../../todo/issue-todo-checklist/001-todo-issue-todo-checklist.md)

## Commands
- `rg --files docs/issues docs/todo docs/fixbug`: PASS - kiem ke issue/todo/fixbug.
- `rg "Trang thai:|Severity:|# Todo|# " docs/todo docs/issues -n`: PASS - lay status va severity.
- `flutter test`: SKIPPED - chi sua docs checklist.

## Loi/Rui ro
- Da fix: Khong co, phien nay chi tao checklist.
- Chua fix: 10 todo van con pending.
- Can kiem tra tiep: Cap nhat checklist sau moi lan fix issue.
