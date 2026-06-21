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
8. `.codex/history/OPEN_RISKS.md`

If the user says the context is for a specific work type, switch to that workflow and read only the matching domain context.

## Do Not Read By Default

- Raw `lib/**`
- Raw `test/**`
- Raw `docs/worklog/**/*.md`
- Entire `docs/DD/**`
- Entire `docs/supabase/**`

Open those only after a workflow or domain file requires them.
