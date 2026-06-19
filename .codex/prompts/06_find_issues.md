Doc `.codex/AGENTS.md`, `.codex/PROJECT_MAP.md`, `.codex/DOCS_WORKFLOW.md`, `.codex/ISSUE_TODO_WORKFLOW.md`.
Chon mode `find-issues`. Chon dung 1 playbook neu pham vi thuoc module cu the.

Pham vi tim bug:
[MODULE/FILE/FLOW]

Yeu cau:
1. Chi tim bug/rui ro, khong sua code, khong tao todo, khong refactor.
2. Dung `rg` de lay context toi thieu: file chinh, import truc tiep, usage, test gan nhat.
3. Ghi findings theo severity: blocker/high/medium/low.
4. Moi finding phai co bang chung: file/line/log/command/case tai hien.
5. Tao issue tai `docs/issues/<issue-slug>/<NNN>-issue-<issue-slug>.md` cho loi da du bang chung.
6. Cap nhat worklog neu co tao docs.
7. Bao cao issue da tao, issue chua du bang chung, va pham vi chua doc de tiet kiem token.
