# DOCS_WORKFLOW - Worklog And Project Docs

Use this file for any session that changes code, tests, docs, `.codex`, issues, todos, DD, or performs substantial review/analysis.

## Required Docs

- Always create/update a worklog for code, review, test, docs, issue/todo, DD, context update, or substantial analysis.
- Add detailed docs when relevant:
  - Feature/change: `docs/features/<slug>/<NNN>-feature-<slug>.md`
  - Bug fix: `docs/fixbug/<slug>/<NNN>-fixbug-<slug>.md`
  - Test result: `docs/test/<slug>/<NNN>-test-<slug>.md`
  - Issue: `docs/issues/<slug>/<NNN>-issue-<slug>.md`
  - Todo: `docs/todo/<slug>/<NNN>-todo-<slug>.md`
  - DD: `docs/DD/<module>/`

## Numbering

- New docs under `docs/worklog`, `docs/features`, `docs/fixbug`, `docs/test`, `docs/issues`, `docs/todo` use `NNN-...md`.
- `NNN` is max existing number in that folder + 1.
- Do not renumber old files.
- Detail docs start with `Commit de xuat: ...`.

## Worklog Location

```text
docs/worklog/<yyyy-mm-dd>/<NNN>-worklog-<slug>.md
```

Use project/user timezone when known: `Asia/Saigon`.

## Worklog Template

```md
Commit de xuat: docs(worklog): ghi nhan phien <slug>

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

- ...

## Commands

- `command`: PASS/FAIL/SKIPPED - ghi chu

## Loi/Rui ro

- Da fix:
- Chua fix:
- Can kiem tra tiep:

## Ty le hoan thanh

- Hoan thanh:
- Dang do:

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot/can cai thien - ly do
- Muc do hoan thanh task:
- Bang chung kiem chung:
- Diem ton token/chua toi uu:
- Cach toi uu cho phien sau:
- Task-skill can doc lan sau: `.codex/task-skills/<task-key>.md`
```

## DD Rules

- For BD -> DD work, use `.codex/workflows/docs-dd.md`.
- DD must trace to BD IDs, BR/AC/UC, or source headings.
- Keep `Status: Draft` while open decisions affect behavior, schema, security, or acceptance.
- Update `docs/checklist/checklist_create_DD.md` when DD status/checklist changes.

## Issue/Todo Rules

- Use `.codex/ISSUE_TODO_WORKFLOW.md`.
- Do not mix find issue, create issue, create todo, fix issue, and test unless the user requests a chain.

## History Refresh

After creating/updating any worklog, run:

```powershell
powershell -ExecutionPolicy Bypass -File .codex/tools/update_worklog_learning.ps1
```

Include changed `.codex/history/*` files in the same docs/context update.
The refresh also regenerates `.codex/task-skills/*.md`; include those files when their generated content changes.

## Self Optimization

- At the end of each substantial session, use `.codex/history/SESSION_QUALITY_REVIEW.md`.
- Before broad reads/checks, ask how to save tokens while keeping or improving quality.
- Prefer updating generated summaries and task-skills over making future agents read raw worklogs by default.

## Safety

- Do not write secrets, API keys, tokens, passwords, health PII, raw AI prompt/response, raw webhook/payment payloads, or long logs into docs.
- Summarize command failures; do not paste noisy full logs unless required.
- `.codex` files may use ASCII for reliability; user-facing docs should use Vietnamese with correct tone when practical.
