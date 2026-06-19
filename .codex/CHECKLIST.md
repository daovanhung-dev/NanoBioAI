# CODEX CHECKLIST

## Truoc khi sua

- [ ] Xac dinh module chinh va loai task.
- [ ] Doc `AGENTS.md`, `PROJECT_MAP.md`, `DOCS_WORKFLOW.md` neu co sua file.
- [ ] Doc dung 1 playbook lien quan.
- [ ] Dung `rg` tim usage truoc khi doi public API/provider/route/schema.
- [ ] Xac dinh nguyen nhan goc hoac pham vi thay doi.

## Khi sua

- [ ] Sua nho nhat du dung yeu cau.
- [ ] Khong bypass UI -> Provider/Controller -> Repository -> Datasource -> DAO/API.
- [ ] Khong them mock/fake/sample data vao production.
- [ ] Khong hard-code secret/API key, khong sua `.env` that neu khong duoc yeu cau ro.
- [ ] User-facing copy tieng Viet co dau, dung giong Nami.
- [ ] Log neu co phai co prefix module va khong lo secret/du lieu nhay cam.

## Sau khi sua

- [ ] Chay quick check hoac ghi ro ly do skip.
- [ ] Neu doi schema: version + migration + table + model + DAO + onCreate + test.
- [ ] Neu doi notification/native/build: chay full check/build APK neu moi truong cho phep.
- [ ] Tao/cap nhat worklog trong `docs/worklog/<yyyy-mm-dd>/`.
- [ ] Tao/cap nhat docs `features`, `fixbug`, `test`, `issues` neu phat sinh.
- [ ] File docs moi dung `NNN-...md` va dong dau `Commit đề xuất:`.
- [ ] Bao cao cuoi gom: file sua, docs tao/cap nhat, command, ket qua, rui ro.
