# ISSUE_TODO_WORKFLOW - Tim bug, tao issue, tao todo

Muc tieu: tach ro viec tim bug, ghi issue, tao todo, coding, test, va fix issue de tranh lan scope va tiet kiem token.

## Nguon Tham Khao Rut Gon

Workflow nay lay y tuong tu GitHub Issues/Projects, GitLab To-Do, Jira bug tracking va bug triage:

- Issue de capture bug/rui ro co bang chung.
- Todo de chia issue thanh viec co the fix.
- Triage de phan loai, uu tien, assign/track den khi dong.

Khong copy dai noi dung ngoai vao repo. Chi dung cac y tren lam rule van hanh.

## Nguyen Tac Tach Mode Bat Buoc

Moi phien chi duoc chon 1 mode chinh. Khong tu y nhay sang mode khac neu user chua yeu cau ro.

| Mode | Duoc lam | Khong duoc lam |
| --- | --- | --- |
| `find-issues` | Doc context toi thieu, review/tim bug/rui ro, ghi `docs/issues` neu co | Khong sua code, khong refactor, khong tao todo/fix |
| `create-issues` | Chuyen findings/bug thanh file issue trong `docs/issues` | Khong sua code, khong tao todo neu user chua yeu cau |
| `create-todo` | Doc issue da co, chia thanh viec fix ro rang trong `docs/todo` | Khong sua code, khong test, khong tim bug moi |
| `coding` | Lap trinh dung yeu cau feature/change | Khong tim issue lan, khong fix issue ngoai scope |
| `test` | Chay test/analyze/build theo yeu cau, ghi ket qua `docs/test` neu can | Khong sua code khi test fail |
| `fix-issues` | Doc issue + todo lien quan, sua nho nhat de dong issue | Khong refactor lan, khong gom issue khac, khong tao feature moi |

Neu user giao nhieu mode cung luc, tach viec theo thu tu va ghi ro mode tung buoc.

## Luong Tong The Tham Chieu

```text
[Doc DD neu user yeu cau ro
  -> lay context toi thieu
  -> lap plan/hoi chi tiet neu can
  -> coding]
-> test hoac find-issues
-> tao issues neu co
-> doc issues
-> tao todo
-> fix issues
```

Day la luong tong the cua du an, khong co nghia mot phien phai lam tat ca.

## Rule Doc DD

- Chi doc `docs/DD/**` khi user noi ro can lap trinh theo DD, tao feature theo DD, hoac yeu cau doc DD.
- Neu chi fix bug/tim issue/test nho, khong doc DD neu bug khong lien quan product spec.
- Neu code hien tai mau thuan DD: bao ro `code hien tai` vs `DD tam nhin`, khong tu nang scope.

## Tao Issue Trong `docs/issues`

Chi tao issue khi:

- Bug/rui ro co bang chung ro: file/line, log, case tai hien, test fail, hoac architecture violation cu the.
- Loi chua duoc fix trong mode hien tai.
- Loi nam ngoai scope coding/fix hien tai.

Vi tri:

```text
docs/issues/<issue-slug>/<NNN>-issue-<issue-slug>.md
```

Issue phai co:

- `Commit de xuat: docs(issue): ghi nhan loi <slug>`
- Tom tat ngan.
- Severity: blocker/high/medium/low.
- Expected vs actual neu co UI/flow.
- Cach tai hien hoac cach xac minh.
- Evidence: file/line/log/command.
- Pham vi anh huong.
- Huong fix de xuat, nhung khong viet patch code trong issue.

## Tao Todo Trong `docs/todo`

Todo chi duoc tao sau khi da doc issue cu the.

Vi tri:

```text
docs/todo/<todo-slug>/<NNN>-todo-<todo-slug>.md
```

Todo phai co:

- `Commit de xuat: docs(todo): lap todo fix <slug>`
- Link den issue goc.
- Muc tieu dong issue.
- Danh sach task nho, co thu tu.
- File du kien doc/sua.
- Test/command can chay o mode `test` rieng hoac sau khi user yeu cau.
- Dieu khong lam de tranh lan scope.

## Fix Issue Tu Todo

Khi user yeu cau fix issue:

1. Doc `.codex/AGENTS.md`, `.codex/PROJECT_MAP.md`, `.codex/DOCS_WORKFLOW.md`, file nay.
2. Doc todo va issue lien quan truoc.
3. Doc dung 1 playbook theo module.
4. Dung `rg` de xac minh file/usage toi thieu.
5. Sua nho nhat theo todo.
6. Cap nhat `docs/fixbug` neu co sua bug.
7. Cap nhat worklog.
8. Neu test duoc user yeu cau/chay rieng, ghi `docs/test`; neu khong, ghi command SKIPPED va ly do.

## Token Saving Cho Issue/Todo

- Bat dau bang core read pack + file nay + 1 playbook lien quan.
- `find-issues`: doc file user chi dinh, import truc tiep, usage, test lien quan; khong quet toan repo.
- `create-issues`: chi mo source/log toi thieu de xac minh evidence.
- `create-todo`: doc issue goc truoc, chi mo source neu can xac dinh file fix.
- `fix-issues`: doc todo -> issue -> file lien quan; dung khi patch nho nhat da ro.
- Khong paste output dai cua `rg`, `flutter analyze`, `flutter test` vao docs; chi tom tat loi chinh va command.
