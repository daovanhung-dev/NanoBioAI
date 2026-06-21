Commit de xuat: docs(codex): toi uu context theo work type va lich su

# Worklog - Codex Worktype History Skill

## Thoi gian

- Ngay: 2026-06-22
- Bat dau: khong ghi nhan tu dong
- Ket thuc: khong ghi nhan tu dong
- Timezone: Asia/Saigon

## Pham vi

- Loai task: docs-context
- Module chinh: `.codex`, workflow router, domain context, worklog learning, project skill.
- Yeu cau goc: implement plan toi uu `.codex` theo loai cong viec, tao project skill, hoc tu toan bo lich su worklog, sua stale context path.

## Da lam

- Tao layout moi `.codex/workflows/` theo loai cong viec va `.codex/domains/` theo module/domain san pham.
- Rut gon root `.codex/AGENTS.md`, `README.md`, `PROJECT_MAP.md`, `DOCS_WORKFLOW.md`, `CHECKLIST.md`, `ISSUE_TODO_WORKFLOW.md` thanh router/context entrypoint.
- Giu `.codex/playbooks/*` va `.codex/workRule/*` lam alias an toan tro ve layout moi.
- Khoi tao skill project-local `.codex/skills/nanobio-project-agent/` bang skill-creator va thay noi dung template bang workflow NanoBio.
- Tao `.codex/tools/update_worklog_learning.ps1` de doc toan bo `docs/worklog/**/*.md` va sinh `.codex/history/*`.
- Sinh `.codex/history/WORKLOG_INDEX.md`, `LEARNED_SKILLS.md`, `OPEN_RISKS.md`, `HISTORY_REFRESH.md`.
- Cap nhat `.codex/MAP_TREE.md` theo inventory hien tai co loc build/cache/binary-heavy paths.
- Sua parser history de chiu duoc worklog cu bi mojibake va normalize stale source roots.

## File code/docs da sua

- `.codex/workflows/` - tao - workflow context theo loai cong viec.
- `.codex/domains/` - tao - domain context theo module san pham.
- `.codex/history/` - tao - tri thuc sinh tu toan bo worklog.
- `.codex/skills/nanobio-project-agent/` - tao - project-scoped skill cho AI agent.
- `.codex/tools/update_worklog_learning.ps1` - tao - script refresh history.
- `.codex/AGENTS.md` - sua - entrypoint moi cho workflow/domain/history.
- `.codex/PROJECT_MAP.md` - sua - source map va routing cap nhat theo app_versions.
- `.codex/README.md` - sua - cach doc context moi.
- `.codex/DOCS_WORKFLOW.md` - sua - them history refresh sau worklog.
- `.codex/CHECKLIST.md` - sua - checklist theo workflow/domain.
- `.codex/ISSUE_TODO_WORKFLOW.md` - sua - mode issue/todo ngan gon.
- `.codex/playbooks/*` - sua - alias an toan den `.codex/domains/` hoac workflow moi.
- `.codex/workRule/*` - sua - alias an toan den `.codex/workflows/`.
- `.codex/MAP_TREE.md` - sua - inventory hien tai.
- `docs/worklog/2026-06-22/001-worklog-codex-worktype-history-skill.md` - tao - ghi nhan phien.

## Tai lieu lien quan

- `.codex/workflows/README.md`
- `.codex/domains/README.md`
- `.codex/history/LEARNED_SKILLS.md`
- `.codex/skills/nanobio-project-agent/SKILL.md`

## Commands

- `python C:\Users\daohu\.codex\skills\.system\skill-creator\scripts\init_skill.py nanobio-project-agent --path .codex\skills --resources references ...`: PASS - tao skill scaffold.
- `powershell -ExecutionPolicy Bypass -File .codex\tools\update_worklog_learning.ps1`: PASS - sinh history tu worklog corpus; lan dau fail do syntax PowerShell da duoc fix.
- `rg -n "lib/features|lib/services/ai|lib/services/notifications|TOKEN_SAVING_RULES|docs/DD/README|MODULE_INDEX|prompts" .codex`: PASS - khong con stale reference; `rg` exit 1 do khong co match.
- `python -m pip install PyYAML`: PASS - cai dependency can cho validator skill-creator trong moi truong hien tai.
- `python C:\Users\daohu\.codex\skills\.system\skill-creator\scripts\quick_validate.py .codex\skills\nanobio-project-agent`: PASS - `Skill is valid!`.
- `rg --files .codex docs\worklog docs\DD docs\BD docs\supabase`: PASS - xac nhan layout/docs.
- `git diff --check -- .codex docs\worklog`: PASS - chi co warning LF/CRLF tren Windows, khong co whitespace error.
- `flutter analyze` / `flutter test`: SKIPPED - docs/context-only, khong sua runtime Dart.

## Loi/Rui ro

- Da fix: `.codex` khong con bat buoc doc tran lan playbook/workRule; stale references den source root cu da duoc go bo hoac normalize trong history.
- Chua fix: Worktree van co nhieu thay doi runtime va `.env` ngoai scope phien nay; khong cham vao.
- Can kiem tra tiep: Neu muon skill global auto-trigger o moi workspace thi can task rieng de cai vao `~/.codex/skills`.

## Ty le hoan thanh

- Hoan thanh: 100% plan docs-context trong pham vi `.codex`, skill project-local, history learning va validation docs-only.
- Dang do: khong co runtime implementation; Flutter checks duoc skip dung scope.
