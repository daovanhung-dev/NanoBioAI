# Workflow - Docs DD

Use for creating, updating, reviewing, or reading design docs from BD.

## Required Context

- `.codex/AGENTS.md`
- `.codex/PROJECT_MAP.md`
- `.codex/DOCS_WORKFLOW.md`
- `.codex/domains/access-membership-referral.md` for product flow, membership, FamilyPlus, sale/referral.
- Source BD in `docs/BD/`.
- Related existing DD in `docs/DD/`.
- `docs/checklist/checklist_create_DD.md` when updating DD checklists.

## Rules

- DD must trace to BD IDs, BR/AC/UC sections, or explicit source headings.
- Keep `Status: Draft` when open decisions affect behavior, schema, security, or acceptance.
- Do not turn open product questions into technical defaults.
- Product flow DD Q-01..Q-10 remain blockers until PO/Tech Lead decides.

## Completion

- Update DD, checklist, `.codex/MAP_TREE.md`, worklog.
- Run docs-only checks and refresh `.codex/history/`.
