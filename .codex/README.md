# .codex - NanoBio / BioAI

Bo context nay giup Codex lam viec dung kien truc, dung workflow docs, va tiet kiem token cho du an NanoBio/BioAI.

## Cach doc mac dinh

1. Doc `.codex/AGENTS.md`.
2. Doc `.codex/PROJECT_MAP.md` de chon dung module/source.
3. Neu sap code, review, test, hoac sua docs: doc `.codex/DOCS_WORKFLOW.md`.
4. Chi doc 1 playbook lien quan truc tiep trong `.codex/playbooks/`.
5. Dung `rg` truoc khi mo rong source.

Khong doc toan bo `.codex`, `lib/`, `test/`, hoac docs cu neu task chua can.

## File chinh

- `AGENTS.md`: luat van hanh bat buoc, snapshot stack, workflow lam viec.
- `PROJECT_MAP.md`: dinh tuyen task sang dung folder/source/test.
- `DOCS_WORKFLOW.md`: worklog va docs feature/fixbug/test/issue dang ngan.
- `TOKEN_SAVING_RULES.md`: quy tac tiet kiem token.
- `CHECKLIST.md`: checklist truoc/trong/sau khi lam.
- `playbooks/*.md`: luat ngan theo module.
- `prompts/*.md`: prompt mau de giao viec.
- `tool/*`: script quick/full check.

## Snapshot hien tai

- Flutter/Dart app, SDK constraint `^3.9.2`.
- Riverpod `3.3.1`, GoRouter `17.2.3`, sqflite `2.4.2`.
- Supabase `2.12.4`, Gemini SDK `0.4.7`.
- Local notifications `19.5.0`, timezone `0.10.1`.
- SQLite database version: `8`.

Nguon dung nhat van la `pubspec.yaml` va `lib/core/storage/localdb/database_version.dart`.
