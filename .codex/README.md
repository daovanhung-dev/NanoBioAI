# .codex - NanoBio / BioAI

Bo context nay giup Codex lam viec dung kien truc, dung workflow docs, va tiet kiem token cho du an NanoBio/BioAI.

## Cach doc mac dinh

1. Doc `.codex/AGENTS.md`.
2. Doc `.codex/PROJECT_MAP.md` de chon module/source.
3. Neu sap code, review, test, hoac sua docs: doc `.codex/DOCS_WORKFLOW.md`.
4. Neu task la tim bug, tao issue, tao todo, hoac fix issue: doc `.codex/ISSUE_TODO_WORKFLOW.md`.
5. Doc dung 1 playbook lien quan truc tiep trong `.codex/playbooks/`.
6. Dung `rg` truoc khi mo rong source.

Khong doc toan bo `.codex`, `lib/`, `test/`, hoac docs cu neu task chua can. Khi user yeu cau doc toan du an, lap inventory truoc roi doc sau cac hotspot can thiet.

## File chinh

- `AGENTS.md`: luat van hanh bat buoc, snapshot stack, workflow lam viec.
- `PROJECT_MAP.md`: dinh tuyen task sang dung folder/source/test/docs.
- `DOCS_WORKFLOW.md`: worklog va docs feature/fixbug/test/issue/todo.
- `ISSUE_TODO_WORKFLOW.md`: tach mode tim bug, tao issue, tao todo, fix issue.
- `TOKEN_SAVING_RULES.md`: quy tac lay context va tiet kiem token.
- `CHECKLIST.md`: checklist truoc/trong/sau khi lam.
- `playbooks/*.md`: huong dan ngan theo module; chi doc 1 file lien quan.
- `playbooks/access_membership_referral.md`: access gate, membership tier, guest/free/Plus/FamilyPlus va sale/referral.
- `prompts/*.md`: prompt mau de giao viec; khong phai nguon luat chinh.
- `tool/*`: script quick/full check.

## Snapshot hien tai

- Flutter/Dart app, SDK constraint `^3.9.2`.
- Riverpod `3.3.1`, GoRouter `17.2.3`, sqflite `2.4.2`.
- Supabase `2.12.4`, Gemini SDK `0.4.7`.
- Local notifications `19.5.0`, timezone `0.10.1`, flutter_timezone `5.1.0`.
- SQLite database version: `8`.
- Product access map: `v1` = guest/basic, `v2` = authenticated free, `v3` = planned Plus/FamilyPlus, `sale` = independent referral role.

Nguon dung nhat van la `pubspec.yaml` va `lib/core/storage/localdb/database_version.dart`; khong doan.

## Nguyen tac thiet ke context

- `AGENTS.md` la entrypoint ngan cho agent, nhu README rieng cho coding agent.
- File bat buoc doc phai nho, ro, khong lap qua nhieu rule.
- Context chi mo rong theo bang chung: inventory -> file user/loi -> usage -> test -> DAO/service.
- Chi tiet dai nam trong playbook/docs va duoc doc theo nhu cau.
