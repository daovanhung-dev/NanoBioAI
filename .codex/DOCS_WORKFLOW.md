# DOCS_WORKFLOW - Worklog va tai lieu ket qua

Doc file nay truoc khi code, review, test, hoac sua docs. Muc tieu: moi phien co dau vet ngan gon ve yeu cau, file da sua, cach kiem chung, va rui ro.

## Khi nao phai ghi docs

- Luon tao/cap nhat worklog cho phien co code, review, test, sua docs, hoac phan tich loi.
- Tao docs chi tiet them khi phat sinh:
  - Feature moi/mo rong: `docs/features/`
  - Fix bug: `docs/fixbug/`
  - Test/regression/build co ket qua ro: `docs/test/`
  - Loi chua fix duoc hoac ngoai scope: `docs/issues/`
- Neu chi hoi dap/phan tich ngan va khong sua file: khong bat buoc tao worklog, tru khi user yeu cau.

## Quy tac chung

- Khong ghi secret, API key, token, mat khau, thong tin suc khoe nhay cam, raw AI/API response dai.
- Dung tieng Viet co dau, ngan, du tra loi: lam gi, o dau, vi sao, kiem chung the nao, con rui ro gi.
- File chi tiet phai co dong dau: `Commit đề xuất: ...`
- File moi trong `docs/worklog`, `docs/features`, `docs/fixbug`, `docs/test`, `docs/issues` phai danh so `NNN-...md`.
- So `NNN` tinh trong chinh folder chua file do, lay so lon nhat + 1, khong doi so file cu.
- Worklog phai link Markdown toi docs feature/fixbug/test/issue lien quan neu co.

## Vi tri file

```text
docs/worklog/<yyyy-mm-dd>/<NNN>-worklog-<slug>.md
docs/features/<feature-slug>/<NNN>-feature-<feature-slug>.md
docs/fixbug/<bug-slug>/<NNN>-fixbug-<bug-slug>.md
docs/test/<test-slug>/<NNN>-test-<test-slug>.md
docs/issues/<issue-slug>/<NNN>-issue-<issue-slug>.md
```

Ngay dung timezone local cua user/project neu biet.

## Worklog template

```md
Commit đề xuất: docs(worklog): ghi nhận phiên <slug>

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

## Feature template

```md
Commit đề xuất: feat(scope): mo ta ngan

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

## Fix bug template

```md
Commit đề xuất: fix(scope): mo ta ngan

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
- Test/Issue:

## Regression can de y
- ...
```

## Test template

```md
Commit đề xuất: test(scope): mo ta ngan

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

## Issue template

```md
Commit đề xuất: docs(issue): ghi nhận lỗi <slug>

# <Ten issue>

## Tom tat
- ...

## Muc do anh huong
- Severity: blocker/high/medium/low
- Anh huong user:
- Anh huong dev/build/test:

## Cach tai hien
1. ...

## Da xac nhan
- ...

## Gia thuyet
- ...

## Workaround
- ...

## Huong fix de xuat
- ...

## Files/log lien quan
- `path/file`

## Lien ket
- Worklog:
- Feature/Fixbug/Test:
```

## Logging

- Log chi de bat loi, khong che loi.
- Prefix theo module, vi du `[DashboardFlow]`, `[AIService]`, `[NotificationScheduler]`.
- Khong log secret, token, raw response dai, ho so suc khoe chi tiet, hoac PII nhay cam.
- User-facing error khong hien stack trace/exception/query/table.
