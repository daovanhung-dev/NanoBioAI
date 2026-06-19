Doc `.codex/AGENTS.md`, `.codex/PROJECT_MAP.md`, `.codex/DOCS_WORKFLOW.md`, `.codex/ISSUE_TODO_WORKFLOW.md`.
Chon mode `fix-issues` neu bug da co issue/todo, hoac mode `coding` neu user yeu cau sua truc tiep bug/log chua co issue.
Chon dung 1 playbook theo module loi.

Bug/log hoac Issue/Todo:
[PASTE BUG/LOG/ISSUE/TODO]

Yeu cau:
1. Neu co issue/todo: doc issue + todo truoc, chi fix dung pham vi do.
2. Neu chua co issue: xac dinh trieu chung va nguyen nhan goc trong pham vi bug/log user dua.
3. Dung `rg` tim usage truoc khi doi public API/provider/route/schema.
4. Sua nho nhat, khong refactor lan, khong gom issue khac.
5. Chi chay test khi task cho phep hoac user yeu cau; neu khong, ghi command can chay la SKIPPED.
6. Tao/cap nhat `docs/fixbug/<bug-slug>/<NNN>-fixbug-<bug-slug>.md` neu co sua bug.
7. Cap nhat worklog va link toi docs lien quan.
8. Neu phat hien loi khac ngoai scope, chi ghi `docs/issues/...` khi user cho phep hoac do la blocker truc tiep.
9. Bao cao nguyen nhan, file sua, docs, command da chay/SKIPPED, rui ro.
