# Workflow - Coding

Use for feature implementation or behavior changes.

## Required Context

- `.codex/AGENTS.md`
- `.codex/PROJECT_MAP.md`
- `.codex/DOCS_WORKFLOW.md`
- `.codex/history/LEARNED_SKILLS.md`
- One domain file from `.codex/domains/`
- BD/DD only when the task is product behavior, new feature, or user explicitly says to code from DD.
- `docs/checklist/checklist_complete_DD.md`, then `docs/checklist/checklist_task_coding.md`, when coding from or affecting DD modules.

## DD Progress Gate

- Before coding DD-related behavior, read `docs/checklist/checklist_complete_DD.md` to identify the current module, `DD readiness %`, `Coding progress %`, blockers, and next step.
- Then read `docs/checklist/checklist_task_coding.md` for prior-session coding notes and upcoming work.
- If the selected DD module is still `Draft` and an open question blocks the behavior, stop before inventing product rules and record the gap in the checklist/worklog.
- After coding, update `docs/checklist/checklist_complete_DD.md` with new evidence/progress and update `docs/checklist/checklist_task_coding.md` with the next concrete tasks.

## Rules

- Follow `Presentation -> Provider/Controller -> Repository -> Datasource -> DAO/API`.
- Choose version by access tier: v1 guest/basic, v2 authenticated free, v3 Plus/FamilyPlus planned, sale/referral independent.
- Do not add mock/fake/sample data to production.
- If BD/DD is missing for new business behavior, stop and document the gap instead of inventing behavior.
- Add focused tests when shared logic, persistence, route, quota, or user-facing workflow changes.

## Completion

- Format only touched Dart files if needed.
- Run targeted tests first; quick check when feasible.
- Create/update feature docs or fixbug docs when relevant.
- Update DD progress and next-task checklists when DD module progress changed.
- Create worklog and refresh `.codex/history/`.
