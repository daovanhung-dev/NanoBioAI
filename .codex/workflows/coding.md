# Workflow - Coding

Use for feature implementation or behavior changes.

## Required Context

- `.codex/AGENTS.md`
- `.codex/PROJECT_MAP.md`
- `.codex/DOCS_WORKFLOW.md`
- `.codex/history/LEARNED_SKILLS.md`
- One domain file from `.codex/domains/`
- BD/DD only when the task is product behavior, new feature, or user explicitly says to code from DD.

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
- Create worklog and refresh `.codex/history/`.
