---
name: nanobio-project-agent
description: Project-scoped workflow and context router for NanoBio/BioAI. Use when Codex is working inside this repo and needs to load the right .codex workflow, domain playbook, worklog-derived lessons, source map, docs workflow, issue/todo workflow, DD creation workflow, Supabase context, or validation commands without reading unnecessary repo context.
---

# NanoBio Project Agent

Canonical project-local skill. The repo-discovered wrapper at `.agents/skills/nanobio-project-agent/SKILL.md` exists only to route Codex here.

## Quick Start

1. Confirm the current workspace is `nano_app`.
2. Read `.codex/AGENTS.md`, `.codex/PROJECT_MAP.md`, and `.codex/history/LEARNED_SKILLS.md`.
3. Select exactly one workflow from `.codex/workflows/` based on the user request.
4. Read `.codex/task-skills/README.md` and the matching generated task-skill if present.
5. Read only the matching domain file from `.codex/domains/` unless the workflow says otherwise.
6. If the selected task is creating or updating a module DD from BD, read `.codex/skills/create-dd-from-bd/SKILL.md`.
7. If the user only says "doc context" or "read .codex" without a work type, follow `.codex/workflows/context-read.md`.

## Workflow Selection

Use `references/context-router.md` for trigger phrases and workflow/domain routing.

Core workflows:

- `context-read`: read project context or .codex.
- `coding`: implement a feature or behavior change.
- `bugfix`: fix a concrete bug not already represented by issue/todo docs.
- `fix-issues`: fix an existing docs issue through a todo.
- `test`: run or document tests without changing runtime code.
- `find-issues`: audit/review and create issue docs, no code fixes.
- `create-issues`: convert findings to issue docs.
- `create-todo`: convert issue docs to todo docs.
- `docs-dd`: create/update/read DD from BD. For module DD creation, use the `create-dd-from-bd` project skill.
- `docs-context`: update .codex, project docs, checklists, maps, or context rules.
- `refactor-scaffold`: restructure version/module scaffolds.
- `supabase-schema`: work on Supabase SQL/RLS/membership/family/sale schema docs.

## Domain Selection

Use `references/domain-map.md` when a task touches app code or product docs. Prefer one domain file; add `access-membership-referral.md` only when auth, quota, membership, FamilyPlus, sale, or referral logic is involved.

## History Learning

Use `references/worklog-learning.md` for the rule: after any session creates or updates a worklog, run `.codex/tools/update_worklog_learning.ps1` so `.codex/history/` and `.codex/task-skills/` reflect the full worklog corpus.

Do not read raw `docs/worklog/**/*.md` by default. Read `.codex/history/WORKLOG_INDEX.md`, `.codex/history/LEARNED_SKILLS.md`, and the matching generated task-skill first; open raw worklogs only when a workflow needs evidence or historical details.

Do not read `.codex/MAP_TREE.md` or `.codex/history/RISK_HISTORY.md` by default. Open them only when checking inventory, changing context layout, or collecting exact historical evidence.

At the end of a substantial session, add the self-review from `.codex/history/SESSION_QUALITY_REVIEW.md`: output quality, completion, verification evidence, token efficiency, and what should be optimized next.
