# CODEX CHECKLIST

## Truoc Khi Sua

- [ ] Xac dinh mode: coding, test, find-issues, create-issues, create-todo, fix-issues.
- [ ] Xac dinh module chinh bang `.codex/PROJECT_MAP.md`.
- [ ] Doc `AGENTS.md`, `PROJECT_MAP.md`, va `DOCS_WORKFLOW.md` neu co sua file/review/test/docs.
- [ ] Neu task lien quan issue/todo/fix issue: doc `ISSUE_TODO_WORKFLOW.md`.
- [ ] Chi doc `docs/DD/**` khi user yeu cau ro.
- [ ] Doc dung 1 playbook lien quan.
- [ ] Dung `rg` tim usage truoc khi doi public API/provider/route/schema.
- [ ] Khong tron mode: tim issue khong coding, tao todo khong fix, test khong sua code.

## Khi Sua

- [ ] Sua nho nhat du dung yeu cau.
- [ ] Khong bypass UI -> Provider/Controller -> Repository -> Datasource -> DAO/API.
- [ ] Khong them mock/fake/sample data vao production.
- [ ] Khong hard-code secret/API key, khong sua `.env` that neu khong duoc yeu cau ro.
- [ ] User-facing copy tieng Viet co dau, dung giong Nami.
- [ ] Log neu co phai co prefix module va khong lo secret/du lieu nhay cam.

## Sau Khi Sua

- [ ] Chay quick check hoac ghi ro ly do skip.
- [ ] Neu doi schema: version + migration + table + model + DAO + onCreate + test.
- [ ] Neu doi notification/native/build: chay full check/build APK neu moi truong cho phep.
- [ ] Tao/cap nhat worklog trong `docs/worklog/<yyyy-mm-dd>/`.
- [ ] Tao/cap nhat docs `features`, `fixbug`, `test`, `issues`, `todo` neu phat sinh.
- [ ] File docs moi dung `NNN-...md` va dong dau `Commit de xuat:`.
- [ ] Bao cao cuoi gom: file sua, docs tao/cap nhat, command, ket qua, rui ro.
