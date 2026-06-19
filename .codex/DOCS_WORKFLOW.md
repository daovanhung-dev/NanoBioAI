# DOCS_WORKFLOW - Worklog va tai lieu ket qua

Doc file nay truoc khi code, review, test, hoac sua docs. Muc tieu: moi phien co dau vet ngan gon ve yeu cau, file da sua, cach kiem chung, va rui ro.

## Khi Nao Phai Ghi Docs

- Luon tao/cap nhat worklog cho phien co code, review, test, sua docs, hoac phan tich loi dang ke.
- Tao docs chi tiet them khi phat sinh:
  - Feature moi/mo rong: `docs/features/`
  - Fix bug: `docs/fixbug/`
  - Test/regression/build co ket qua ro: `docs/test/`
  - Loi chua fix duoc hoac ngoai scope: `docs/issues/`
  - Todo fix issue sau khi doc issue: `docs/todo/`
- Neu chi hoi dap/phan tich ngan va khong sua file: khong bat buoc tao worklog, tru khi user yeu cau.
- Moi phien chi lam dung mode: coding/test/find-issues/create-issues/create-todo/fix-issues.

## Quy Tac Chung

- Khong ghi secret, API key, token, mat khau, thong tin suc khoe nhay cam, raw AI/API response dai.
- Dung tieng Viet co dau trong docs user-facing; rieng `.codex` co the dung ASCII de tranh loi encoding.
- File chi tiet phai co dong dau: `Commit de xuat: ...`
- File moi trong `docs/worklog`, `docs/features`, `docs/fixbug`, `docs/test`, `docs/issues`, `docs/todo` phai danh so `NNN-...md`.
- So `NNN` tinh trong chinh folder chua file do, lay so lon nhat + 1, khong doi so file cu.
- Worklog phai link Markdown toi docs feature/fixbug/test/issue/todo lien quan neu co.

## Vi Tri File

```text
docs/worklog/<yyyy-mm-dd>/<NNN>-worklog-<slug>.md
docs/features/<feature-slug>/<NNN>-feature-<feature-slug>.md
docs/fixbug/<bug-slug>/<NNN>-fixbug-<bug-slug>.md
docs/test/<test-slug>/<NNN>-test-<test-slug>.md
docs/issues/<issue-slug>/<NNN>-issue-<issue-slug>.md
docs/todo/<todo-slug>/<NNN>-todo-<todo-slug>.md
```

Ngay dung timezone local cua user/project neu biet.

## Worklog Template

```md
Commit de xuat: docs(worklog): ghi nhan phien <slug>

# Worklog - <ten phien>

## Thoi gian

- Ngay:
- Bat dau:
- Ket thuc:
- Timezone:

## Pham vi

- Loai task:
- Module chinh:
- Yeu cau goc:

## Da lam

- ...

## File code/docs da sua

- `path/file` - sua/tao/xoa - ly do

## Tai lieu lien quan

- [Ten docs](../../features/<slug>/001-feature-<slug>.md) - neu co
- Khong phat sinh

## Commands

- `command`: PASS/FAIL/SKIPPED - ghi chu

## Loi/Rui ro

- Da fix:
- Chua fix:
- Can kiem tra tiep:
```

## Feature Template

```md
Commit de xuat: feat(scope): mo ta ngan

# <Ten feature>

## Muc tieu

- ...

## Pham vi

- Bao gom:
- Khong bao gom:

## Luong hoat dong

1. ...

## Du lieu va luu tru

- Nguon doc:
- Noi ghi:
- Table/model/entity:
- Migration/version:

## UI/UX

- Loading:
- Empty:
- Error:
- Success:

## Files

- `path/file` - ly do

## Kiem chung

- Command:
- Ket qua:
- Case da test:

## Lien ket

- Worklog:
- Test/Issue:

## Rui ro

- ...
```

## Fix Bug Template

```md
Commit de xuat: fix(scope): mo ta ngan

# <Ten bug>

## Trieu chung

- ...

## Nguyen nhan goc

- ...

## Cach sua

- ...

## Files

- `path/file` - ly do

## Kiem chung

- Command:
- Ket qua:
- Case da test:

## Lien ket

- Worklog:
- Test/Issue/Todo:

## Regression can de y

- ...
```

## Test Template

```md
Commit de xuat: test(scope): mo ta ngan

# <Ten test>

## Pham vi

- Loai test:
- Module:
- Case bao gom:
- Case chua bao gom:

## Moi truong

- OS:
- Flutter/Dart:
- Device/emulator:

## Commands/Kich ban

- `command`

## Ket qua

- PASS/FAIL/SKIPPED - ghi chu

## Lien ket

- Worklog:
- Feature/Fixbug/Issue:

## Rui ro

- ...
```

## Issue Template

```md
Commit de xuat: docs(issue): ghi nhan loi <slug>

# <Ten issue>

## Tom tat

- ...

## Expected / Actual

- Mong doi:
- Thuc te:

## Muc do anh huong

- Severity: blocker/high/medium/low
- Anh huong user:
- Anh huong dev/build/test:

## Cach tai hien

1. ...

## Da xac nhan

- File/line:
- Log/command/test:
- Case tai hien:

## Gia thuyet

- ...

## Workaround

- ...

## Huong fix de xuat

- ...
- Khong viet patch code trong issue.

## Files/log lien quan

- `path/file`

## Lien ket

- Worklog:
- Feature/Fixbug/Test:
```

## Todo Template

```md
Commit de xuat: docs(todo): lap todo fix <slug>

# Todo - <Ten issue>

## Issue goc

- Issue: [<Ten issue>](../../issues/<issue-slug>/<NNN>-issue-<issue-slug>.md)
- Severity:
- Trang thai: todo

## Muc tieu fix

- ...

## Khong lam trong todo nay

- Khong sua code trong buoc tao todo.
- Khong test/fix issue khac neu khong co yeu cau rieng.

## Cac viec can lam

1. [ ] Doc file/ham lien quan: `path/file`
2. [ ] Xac minh nguyen nhan goc bang `rg`/test lien quan.
3. [ ] Sua nho nhat tai `path/file`.
4. [ ] Cap nhat docs fixbug/worklog sau khi fix.
5. [ ] Chay command kiem chung o mode test hoac khi user yeu cau.

## File du kien anh huong

- `path/file` - ly do

## Command can kiem chung

- `command` - muc dich

## Rui ro can de y

- ...
```

## Logging

- Log chi de bat loi, khong che loi.
- Prefix theo module, vi du `[DashboardFlow]`, `[AIService]`, `[NotificationScheduler]`.
- Khong log secret, token, raw response dai, ho so suc khoe chi tiet, hoac PII nhay cam.
- User-facing error khong hien stack trace/exception/query/table.

## Checklist

- Mọi công việc điều phải cập nhật checklist, nếu không có checklist thì phải tạo
- Những task như:
  1. Coding: Phải có checklist để kiểm tra xem nhưng DD nào đã được coding
  2. Issues: Kiểm tra xem những issues nào đã được tạo todo
  3. Todo: Kiểm tra xem nhưng todo đã được làm
