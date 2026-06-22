# Workflow - Context Read

Use when the user asks to read `.codex`, read project context, or does not specify a work type.

## Read Order

1. `.codex/README.md`
2. `.codex/AGENTS.md`
3. `.codex/PROJECT_MAP.md`
4. `.codex/workflows/README.md`
5. `.codex/domains/README.md`
6. `.codex/history/WORKLOG_INDEX.md`
7. `.codex/history/LEARNED_SKILLS.md`

Read `.codex/history/OPEN_RISKS.md` only when the requested context touches release readiness, auth, Supabase, DD status, or testing.

If the user says the context is for a specific work type, switch to that workflow and read only the matching domain context.

## Do Not Read By Default

- Raw `lib/**`
- Raw `test/**`
- Raw `docs/worklog/**/*.md`
- `.codex/history/RISK_HISTORY.md`
- `.codex/MAP_TREE.md`
- Entire `docs/DD/**`
- Entire `docs/supabase/**`

Open those only after a workflow or domain file requires them.
