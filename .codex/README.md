# .codex - NanoBio / BioAI

Bo context nay giup Codex lam viec dung workflow, dung module, va khong doc thua context.

## Cach Doc Mac Dinh

1. Doc `.codex/AGENTS.md`.
2. Doc `.codex/PROJECT_MAP.md`.
3. Doc `.codex/history/LEARNED_SKILLS.md`.
4. Chon 1 workflow trong `.codex/workflows/`.
5. Doc `.codex/task-skills/README.md` va task-skill tuong ung neu co.
6. Chon 1 domain trong `.codex/domains/` neu task cham code/product.

Neu user chi noi "doc context", "doc .codex", hoac khong noi loai cong viec: doc `.codex/workflows/context-read.md`, `.codex/workflows/README.md`, `.codex/domains/README.md`, `.codex/task-skills/README.md`, va `.codex/history/*`. Khong doc raw `lib/`, `test/`, `docs/DD/`, hoac raw worklog neu workflow khong yeu cau.

## Cau Truc

- `AGENTS.md`: entrypoint ngan cho agent.
- `PROJECT_MAP.md`: source map va routing task sang module.
- `workflows/`: context theo loai cong viec.
- `domains/`: context theo module/domain san pham.
- `history/`: tri thuc rut ra tu toan bo `docs/worklog`.
- `task-skills/`: skill sinh tu dong theo loai task tu lich su worklog.
- `skills/nanobio-project-agent/`: skill project-local cho AI agent.
- `tools/update_worklog_learning.ps1`: refresh `history/` sau khi co worklog moi.
- `tool/`: script check runtime hien co.
- `playbooks/`, `workRule/`: alias an toan cho link cu, tro ve `domains/` va `workflows/`.

## Snapshot

- Flutter/Dart SDK `^3.9.2`.
- Riverpod `3.3.1`, GoRouter `17.2.3`, sqflite `2.4.2`.
- Supabase `2.12.4`, Gemini SDK `0.4.7`.
- Local notifications `19.5.0`, timezone `0.10.1`, flutter_timezone `5.1.0`.
- SQLite database version: `DatabaseVersion.currentVersion = 8`.
- Product access map: `v1` guest/basic, `v2` authenticated free, `v3` Plus/FamilyPlus planned, `sale_referral` independent.

Nguon dung nhat van la `pubspec.yaml` va `lib/core/storage/localdb/database_version.dart`.

## History Learning

Sau moi phien tao/cap nhat `docs/worklog/**`, chay:

```powershell
powershell -ExecutionPolicy Bypass -File .codex/tools/update_worklog_learning.ps1
```

Sau do doc `.codex/history/LEARNED_SKILLS.md` va task-skill phu hop o cac phien tiep theo de AI agent hoc lai tu toan bo lich su lam viec ma khong can nap raw worklog.

Moi phien dang ke phai tu hoi cach tiet kiem token trong khi giu hoac tang chat luong, roi ghi cau tra loi vao phan self-review cua worklog.
