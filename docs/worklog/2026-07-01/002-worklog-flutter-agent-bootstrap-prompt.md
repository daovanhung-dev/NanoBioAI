Commit de xuat: docs(prompt): cap nhat bootstrap context Flutter agent

# Worklog - Flutter agent bootstrap prompt

## Thoi gian

- Ngay: 2026-07-01
- Bat dau: 17:34
- Ket thuc: 17:36
- Timezone: Asia/Saigon

## Pham vi

- Loai task: docs-context
- Module chinh: `docs/prompts/bootstrap-ai-context.md`
- Yeu cau goc: Cap nhat prompt bootstrap agent context de voi 1 lenh prompt co the tao/merge workflow, context, docs, skill, testing, DD va validation cho cac du an Flutter theo pattern NanoBio-style nhung khong copy noi dung product NanoBio.

## Da lam

- Cap nhat prompt hien co thay vi tao file moi.
- Them one-command prompt cho Flutter repositories.
- Them discovery rieng cho `pubspec.yaml`, `analysis_options.yaml`, `melos.yaml`, `build.yaml`, platform folders, env templates, flavor/target, codegen va validation surface.
- Them kien truc target context gom root `AGENTS.md`, `.codex/AGENTS.md`, `.codex/PROJECT_MAP.md`, `.codex/DOCS_WORKFLOW.md`, workflows, task-skills, domains, DD skill, BD/DD/checklist/worklog docs.
- Them rule cot loi: chon mot workflow, doc workflow -> task-skill -> domain, uu tien `rg`/index, khong inventory toan bo `lib/`, DD traceability, worklog/self-review/history refresh va validation theo workflow.
- Giu prompt generic cho Flutter projects; khong them module/product/business rule NanoBio vao target context.
- Sua stale context path `.codex/domains/ui-Nabi.md` thanh `.codex/domains/ui-nami.md` de docs integrity pass.

## File code/docs da sua

- `docs/prompts/bootstrap-ai-context.md` - sua - bo sung Flutter agent context bootstrap architecture va rules.
- `docs/worklog/2026-07-01/002-worklog-flutter-agent-bootstrap-prompt.md` - tao - ghi nhan phien docs-context.
- `.codex/Design.md` - sua - cap nhat stale path domain UI.
- `.codex/PROJECT_MAP.md` - sua - cap nhat stale path domain UI.
- `.codex/MAP_TREE.md` - sua - cap nhat stale path domain UI.
- `.codex/domains/README.md` - sua - cap nhat stale path domain UI.
- `.codex/playbooks/ui_nami.md` - sua - cap nhat stale path domain UI.
- `.codex/skills/nanobio-project-agent/references/domain-map.md` - sua - cap nhat stale path domain UI.
- `.codex/history/*` va `.codex/task-skills/*` - cap nhat tu refresh script - hoc lai worklog moi.

## Tai lieu lien quan

- `.codex/workflows/docs-context.md`
- `.codex/task-skills/docs-context.md`
- `.codex/DOCS_WORKFLOW.md`
- `.codex/history/SESSION_QUALITY_REVIEW.md`

## Commands

- `rg -n "Flutter|pubspec|AGENTS.md|\.codex|workflows|task-skills|docs-dd|worklog|DD" docs/prompts/bootstrap-ai-context.md`: PASS - prompt co cac khai niem Flutter/context can thiet.
- `rg -n "NanoBio|NamiAI|Nabi|M01|M19" docs/prompts/bootstrap-ai-context.md`: PASS - chi co 2 dong `NanoBio-style` o muc workflow pattern, khong co product/module rule.
- `powershell -ExecutionPolicy Bypass -File .codex/tools/update_worklog_learning.ps1`: PASS - refresh tu 59 worklog files.
- `rg -n "ui-Nabi\.md|\.codex/domains/ui-Nabi\.md" .codex`: PASS - exit 1 vi khong con stale reference.
- `powershell -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1`: PASS.
- `git diff --check`: PASS - chi co warning line ending LF/CRLF, khong co whitespace error.

## Loi/Rui ro

- Da fix: prompt bootstrap Flutter context va stale `.codex/domains/ui-Nabi.md` references.
- Chua fix: none trong pham vi docs-context nay.
- Can kiem tra tiep: none; khong chay Flutter analyze/test vi khong doi runtime code.

## Ty le hoan thanh

- Hoan thanh: prompt edits, stale path fix, history refresh, docs integrity va diff whitespace checks.
- Dang do: none.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - prompt giu duoc Step 1-5/fan-out va them Flutter/NanoBio-style workflow architecture theo yeu cau.
- Muc do hoan thanh task: hoan thanh day du theo plan docs-context.
- Bang chung kiem chung: targeted `rg` checks, history refresh, `.codex/tools/validate_codex_integrity.ps1`, va `git diff --check` pass.
- Diem ton token/chua toi uu: can doc prompt hien co va workflow docs-context, khong can doc raw `lib/` hay raw DD.
- Cach toi uu cho phien sau: khi sua prompt bootstrap, doc `docs/prompts/bootstrap-ai-context.md`, `.codex/workflows/docs-context.md`, `.codex/task-skills/docs-context.md`, roi dung targeted `rg`.
- Task-skill can doc lan sau: `.codex/task-skills/docs-context.md`
