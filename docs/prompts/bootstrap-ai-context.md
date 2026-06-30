# Bootstrap AI-Agent Context

**Purpose / Goal:** This file is a reusable, copy-paste meta-prompt. Hand it to any AI coding agent working in any repository. Its goal is to make that repository's AI-agent context optimal — so every agent that touches the project works more efficiently. The agent will first understand the project, then detect whether AI-agent context files already exist, and BRANCH: create fresh, tailored context if none exist, or carefully MERGE in the strongest patterns if some already exist — always using a single source of truth so duplicate copies never diverge.

---

## How to use this prompt

- Paste the entire contents of this file into your AI coding agent, or point the agent at this file (e.g. "Read and execute `bootstrap-ai-context.md`").
- The agent executes the steps in order: **Step 1 → Step 2 → {Step 3A or Step 3B} → Step 4 → Step 5.** Both branches (3A create, 3B merge) converge into Step 4 (fan-out) and Step 5 (verify).
- Write all output in the project's existing documentation language (default English if none is established). Keep this prompt's own English section/table headers in the template as a starting point; translate them to match the project when its docs are in another language.
- The agent must run **read-only exploration first** and must **not** create or modify any file until Step 3. Before any large rewrite of existing context, it must pause and confirm with the user.

---

## STEP 1 — Discover (read-only; write nothing yet)

Explore the repository to understand structure and tech stack. Use read/list/grep tooling only. Build a model; do not author files yet. For large monorepos, go **breadth-first and sample** — do not exhaustively read every file.

Checklist:

- [ ] **Root listing** — list the repo root (including dotfiles/dotdirs).
- [ ] **Manifests / package files** — e.g. `package.json`, `pyproject.toml`, `Pipfile`, `requirements.txt`, `go.mod`, `Cargo.toml`, `pom.xml`, `build.gradle`, `composer.json`, `Gemfile`, `*.csproj`. Note languages, frameworks, and versions. **If no recognized manifest exists, infer commands from CI config, `Makefile`/`Taskfile`/`justfile`, and scripts — this is the fallback for unknown stacks.**
- [ ] **Monorepo layout** — workspaces, `packages/*`, `apps/*`, nx/turbo/lerna/pnpm-workspace configs. Note each package's own tech stack.
- [ ] **Build / run / test / lint / format commands** — read scripts in manifests, `Makefile`, `Taskfile`, `justfile`. Capture exact, copy-pasteable invocations (incl. non-obvious flags, preferred test runner, how to run a single test).
- [ ] **Build configs** — tsconfig, vite/webpack, bundler, compiler, Docker/compose, env templates (`.env.example`).
- [ ] **CI** — `.github/workflows/`, `.gitlab-ci.yml`, etc. CI reveals the real, enforced build/test/lint commands.
- [ ] **Existing docs** — `README.md`, `CONTRIBUTING.md`, `docs/`, ADRs, wiki pointers. Note conventions, branch/PR rules.
- [ ] **Architecture & boundaries** — entry points, module/route registration, source-of-truth files (route/permission registries), tenant/schema boundaries, naming patterns.
- [ ] **AI/editor tooling signals** — existing agent-context files, editor configs (`.vscode/`, `.idea/`), CI steps invoking AI tools, lockfile/dotfile hints. Determine **which AI tools the team actually uses** (feeds Steps 2 and 4).
- [ ] **Secrets handling** — how/where credentials live (look for gitignored `*.local.*`, `.env`). Never read or echo secret values.

**Output of Step 1:** record findings to a temporary scratch note (not a tracked file) using the same field names as the Step 3A root-file template (project summary, commands, architecture, conventions, gotchas, docs map) plus the list of AI tools the team uses. This makes transfer into Step 3 mechanical and prevents loss across steps.

---

## STEP 2 — Detect existing AI context

Look for these files/dirs (root and, for monorepos, **each package**). Check existence read-only:

| Tool | Files / dirs to look for |
|---|---|
| Claude Code | `CLAUDE.md`, `.claude/`, `.claude/rules/*.md`, `CLAUDE.local.md` |
| Cross-tool standard | `AGENTS.md` (root and nested), `AGENTS.override.md` |
| Cursor | `.cursor/rules/*.mdc`, `.cursorrules` (legacy) |
| GitHub Copilot | `.github/copilot-instructions.md`, `.github/instructions/*.instructions.md` |
| Windsurf | `.windsurf/rules/*.md` (newer builds may prefer `.devin/rules/`), `.windsurfrules` (legacy) |
| Cline | `.clinerules/` (dir or file), root `AGENTS.md` |
| Roo Code | `.roo/rules/`, `.roorules` (legacy) |
| Gemini CLI | `GEMINI.md`, `.gemini/settings.json` (check `context.fileName`) |
| Aider | `CONVENTIONS.md`, `.aider.conf.yml` (check `read:` key) |

**Decision rule (mechanical):**

Treat a context file as **REAL** if it contains any of: a command not derivable from the manifests, an architecture / source-of-truth / invariant statement, a project-specific gotcha, or hand-written conventions. Treat it as **STUB** (counts as none) if it only restates generic best-practice prose, contains only TODO/placeholder/boilerplate, has fewer than ~5 lines of project-specific non-derivable guidance, or merely repeats what manifests already declare.

- **NONE-EXIST** — no REAL files present at a given location. → **STEP 3A**.
- **SOME-EXIST** — one or more REAL files present. → **STEP 3B**.
- **Borderline** — if you cannot decide, default to **STEP 3B (merge)**: it is the safer, non-destructive branch. Ask the user.

**Monorepo / mixed state:** the decision is **per location**, not repo-global. The root may be SOME while a package is NONE (or vice versa). Run 3B where REAL context exists and 3A where it does not, then converge all locations into one canonical source in Step 4.

Also record (confirming Step 1) **which tools the team actually uses** — from tool-file presence, editor configs, lockfile hints, CI steps. You will fan out only to those in Step 4.

---

## Canonical source (shared by 3A and 3B)

Before authoring, fix the **single canonical file** that all tools will reference:

- **If context already exists and centers on one file** (most content lives there and/or other tools already reference it), keep that as canonical — do not impose a new one.
- **Otherwise choose `AGENTS.md`** (broadest native support). If the project is Claude-Code-centric, `CLAUDE.md` may be canonical instead.
- In monorepos, the canonical file sits at the root; add nested per-package files (nearest-wins) only where a package needs its own stack/rules.

---

## STEP 3A — Create (no existing context)

Create a single, concise, always-loaded **root context file** (the canonical file chosen above) as the source of truth. For small/medium projects this one file is enough. For larger projects, add an on-demand detail directory (progressive disclosure).

Design rules:

- Keep the root file short (target < ~200 lines). It orients and links out; it does not inline everything.
- **Lead with commands** the agent cannot guess.
- Apply the **deletion test** to every line: if removing it would NOT cause a mistake, cut it.
- Exclude anything derivable from code, secret, or volatile (status snapshots, sprint state, fragile paths).
- Use imperative, verifiable directives ("Use 2-space indent", "Run `npm test` before commit") — not aspirations ("write clean code").

**Safety:** if you discover any existing hand-written context after starting 3A, **stop and switch to 3B (merge)** — never overwrite.

### Root-file template (fill in the blanks)

```markdown
# <PROJECT NAME> — AI Agent Guide

One-paragraph: what this project is and its top-level layout.
<e.g. Mono-repo: `server/` (Python/Flask API) + `client/` (Vue 3 SPA).>

## Commands
| Task | Command | Notes |
|---|---|---|
| Install | `<cmd>` | |
| Run (dev) | `<cmd>` | |
| Build | `<cmd>` | |
| Test (all) | `<cmd>` | |
| Test (single) | `<cmd>` | non-obvious; fill in |
| Lint | `<cmd>` | |
| Format | `<cmd>` | |

## Architecture (only what code-reading won't reveal)
- Entry points: <file(s)>
- Single source of truth: <file> — <rule, e.g. "add routes here FIRST, then reference">
- Boundaries / invariants: <tenant/schema, identifiers that MUST match across files>

## Conventions
- Naming: <pattern>
- Branch / commit / PR: <rules>
- Env vars / dev quirks: <required vars; where secrets live (gitignored path), never inline>

## Gotchas (things the agent would get WRONG without this)
- <non-obvious behavior / "do not X" rule>

## Docs map (read on demand)
| File | When to read |
|---|---|
| <docs/architecture.md> | <trigger phrase> |
| <docs/db.md> | <trigger phrase> |

## Quick recipes
**<Common multi-file task>:**
1. <step> → verify: <check>
2. <step> → verify: <check>
(Details → <linked doc>)

## Behavioral guidelines
- Simplicity first: minimum code that solves the problem; no speculative abstractions.
- Surgical changes: every changed line traces to the request; don't refactor unrelated code.
- Clarify before coding: if multiple interpretations exist, ask — don't pick silently.
- Verify: after changes run <test/build/lint cmd> and show command + output as evidence.
- Never commit secrets; never run destructive/DB-write actions without explicit approval.
```

### Optional detail directory (larger projects — progressive disclosure)

Create a `docs/` tree (the neutral, tool-agnostic default), linked from the root **Docs map**, loaded only when a task needs it:

| Layer | File(s) | Holds |
|---|---|---|
| Index | `README.md` | Docs index + numbered read-order + project snapshot |
| Architecture | `architecture/*.md` | How subsystems work and how to extend them |
| Data | `db/access.md`, `db/schemas.md` | Query templates (placeholders, no secrets), schema inventory |
| Reference | `reference/*.md` | Stable enumerations (endpoints, permissions) — tables, not prose |
| Feature rules | `features/*.md` or `screens/*.md` | Volatile per-feature gotchas, isolated from shared docs |
| Process | `conventions.md`, `debug-checklist.md` | Cross-cutting rules; symptom → fix lookup |

Conventions for the tree: every doc links to its siblings and **down to the exact source files** it documents; isolate stable tables from volatile prose; quarantine per-feature quirks; date volatile inventories ("Snapshot YYYY-MM-DD") and label WIP/placeholder areas so the agent re-verifies. Keep secrets only in gitignored `*.local.*` files; use `<HOST>`/`<PASSWORD>` placeholders in tracked docs.

**Handoff:** the root file created here is the canonical source — proceed to **STEP 4** to register it for the other tools the team uses, then **STEP 5** to verify.

---

## STEP 3B — Merge (context already exists)

Do **not** wipe and regenerate. Preserve the team's existing workflow and graft in the strongest patterns.

1. **Read everything that exists** (Step 2 hits) and the project docs. Understand the current structure, the canonical/source-of-truth file, and any tool-specific scoping already in use.
2. **Preserve**: existing rules, voice, file locations, and any deliberate tool-specific files. Match the existing style even if you'd do it differently.
3. **Preservation guard — do not break references.** Before grafting, scan Step 2 hits for cross-file links that point at current locations: Claude `@path` imports, Aider `read:` keys, Gemini `context.fileName`, Copilot/Cursor/Windsurf `applyTo`/`globs`/`trigger` scoping. **Do not move or rename any file these reference.** Add new content in place or in new linked docs.
4. **Graft in (only what's missing)** the high-value patterns:
   - A **command-first** block if commands are scattered or absent.
   - A **Docs map table** with a *When to read* column if detail files exist but aren't indexed.
   - **Progressive disclosure**: if the root file is bloated, move depth into linked on-demand docs and leave links behind — but relocating existing content is a **large rewrite requiring sign-off** (item 7); never move referenced files (item 3).
   - **Quick recipes** for the project's common multi-file tasks.
   - **Source-of-truth + edit-order** callouts and **cross-file coupling** invariants.
   - A **symptom → fix** debug checklist.
5. **Identify cross-tool duplication** (do not consolidate yet): note where multiple tool files repeat the same body. **Defer actual consolidation to Step 4**, recording the intended canonical target chosen in the "Canonical source" section above.
6. **Reconcile contradictions**: if two rules/files conflict, surface them to the user and propose one resolution; do not silently pick. Replace duplicated content with a pointer to one canonical copy ("Details → …") rather than maintaining two.
7. **Confirm before large rewrites**: summarize proposed changes and get user sign-off before restructuring, moving substantial content, or splitting a bloated root file. Make surgical edits otherwise.

**Handoff:** proceed to **STEP 4** to consolidate to the canonical source and fan out, then **STEP 5** to verify.

---

## STEP 4 — Multi-tool fan-out (single source of truth, zero drift)

Use the canonical file fixed in the "Canonical source" section. Every other tool references/imports/derives from it instead of holding a divergent copy. **Generate tool files only for tools the team actually uses** (Steps 1–2). In a greenfield (NONE-EXIST) repo, create **only the single canonical file plus pointers for tools evidenced by editor configs / CI / lockfiles** — do not create one file per row in the table.

**Reference mechanism depends on the tool:** a one-line "see canonical" pointer only achieves zero drift for tools with a real import directive (Claude `@path`, Gemini `@file`, Aider `read:`). Tools **without** imports (Copilot IDE, Cursor `.mdc`, Windsurf) cannot import — for them the zero-drift options are: (a) native `AGENTS.md` auto-read where the tool supports it, (b) a **symlink** to the canonical file, or (c) a **CI/script generation step** from the canonical file. Prefer a symlink or generator over a hand-copied body.

**Surface caveat:** "supports `AGENTS.md`" is per-tool and often per-surface. Where both a canonical file and a tool-native file are loaded together, do **not** duplicate content across them — keep the tool-native file thin.

| Tool | Native file(s) | Format | How to point at the canonical source |
|---|---|---|---|
| Cross-tool | `AGENTS.md` | Plain Markdown, no required fields | The canonical file. Root; add nested `AGENTS.md` per package in monorepos (nearest wins). |
| Claude Code | `CLAUDE.md` | Plain MD; supports `@path` imports | Put `@AGENTS.md` at top, then Claude-specific notes below. (`@`-import expands inline at launch and still costs context budget. Symlink only if Admin/Dev Mode on Windows; import is safer.) |
| Cursor | `.cursor/rules/*.mdc`, or root `AGENTS.md` | `.mdc` = MD + YAML frontmatter (`description`, `globs`, `alwaysApply`). Cursor 2.2+ may store each rule as a folder `.cursor/rules/<name>/RULE.md` with the same frontmatter; flat `*.mdc` still works. | Reads root `AGENTS.md` directly (no `.mdc` import directive). Use `.mdc` only for path-scoped/extra rules; for shared content use a symlink/generator, not a copy. |
| GitHub Copilot | `.github/copilot-instructions.md`; `.github/instructions/*.instructions.md` | Plain MD; instructions files need `applyTo` glob frontmatter | Copilot **coding agent, code review, and CLI** read root `AGENTS.md`; **VS Code inline/chat** read `.github/copilot-instructions.md` (+ `*.instructions.md`) and have **no** `@import`. For a single source, make `copilot-instructions.md` a thin pointer (one-line "See ../AGENTS.md" plus essentials) or generate it via CI/symlink. If both `AGENTS.md` and `copilot-instructions.md` exist, **both** load — avoid duplicating content. |
| Windsurf | `.windsurf/rules/*.md` (newer builds may prefer `.devin/rules/`; `.windsurf` still read as fallback), or root `AGENTS.md` | MD + `trigger:` frontmatter (`always_on`/`glob`/`manual`/`model_decision`) | Reads root `AGENTS.md`. Keep each rule file ≤12k chars; total active-rules budget is also limited and **overflow is silently dropped** — keep `always_on` rules minimal. No import directive; use symlink/generator for shared content. |
| Cline | `.clinerules/` (dir or file), root `AGENTS.md` | Modular MD; optional `paths` frontmatter | Reads project-root `AGENTS.md`; or add a `.clinerules/` file that references it. |
| Roo Code | `.roo/rules/` | Plain MD, alpha-ordered | Add a small rule file referencing `AGENTS.md`. (Verify Roo Code's current status before investing.) |
| Gemini CLI | `GEMINI.md`, `.gemini/settings.json` | Plain MD; `@file` imports | Set `context.fileName` (older Gemini CLI: top-level `contextFileName`) to include `AGENTS.md`, or make `GEMINI.md` contain `@AGENTS.md`. |
| Aider | `CONVENTIONS.md`, `.aider.conf.yml` | Plain MD | Add `read: AGENTS.md` to `.aider.conf.yml` (Aider does not auto-discover). |

Rules:

- **One canonical body on disk.** Other tools reference it (import directive), point to it via symlink, or are generated from it in CI. Never hand-maintain N divergent full copies.
- Reserve tool-native files for **tool-specific scoping/features only** (path-scoped rules, hooks), layered on top of the shared source.
- For guarantees that must happen every time (lint-before-commit, block writes to a path), use the tool's **hooks**, not prose — context files are advisory, not enforced.

---

## STEP 5 — Verify & keep current

Quality checklist before finishing:

- [ ] Root/canonical file is concise; depth is linked, not inlined.
- [ ] Every listed command works. **Run only non-destructive commands** (lint, build, dry-run, single test); for anything that mutates state (install that writes lockfiles, migrate, deploy) confirm against CI config instead of executing.
- [ ] No secrets in any tracked file; secrets referenced by gitignored location only.
- [ ] Nothing derivable-from-code-only (no file-by-file narration, no restating standard language conventions).
- [ ] No contradictions within or across files; one canonical source, others reference/import/derive from it.
- [ ] All internal links resolve; docs link down to real source files.
- [ ] Volatile facts dated; WIP/placeholder areas labeled.
- [ ] Each rule passes the deletion test (removing it would cause a real mistake).
- [ ] A verification path exists (test/build/lint the agent can run for pass/fail).
- [ ] **Branch correctness:** the right branch ran per location (3B preserved prior content; 3A did not overwrite anything). No pre-existing rule was dropped or relocated without user sign-off; all existing imports/references still resolve.
- [ ] **Fan-out correctness:** tool files exist **only** for tools the team actually uses (Step 2 list); none created for unused tools. Every non-canonical tool file references/symlinks/derives from the canonical source and holds **no duplicated full body**. Tool-native files contain only tool-specific scoping, not restated shared content.

**Done-state:** when the checklist passes, report a concise summary of files created/modified/left-unchanged (with the chosen canonical file and the tools fanned out to) and stop.

**Keeping current:** treat the file like code. Add entries from real signals (a mistake the agent repeated, a review catch, a correction you re-typed). Prune outdated lines. If the agent keeps violating a rule, the file is likely too long — cut, don't add emphasis. If it asks about something already documented, the phrasing is ambiguous — sharpen it.

---

## DO / DON'T guardrails

**DO**
- Run read-only discovery before writing anything.
- Lead with exact build/test/run/lint commands.
- Keep one canonical source of truth; have other tools import/symlink/generate from it.
- Make surgical edits to existing files; match their style and language.
- Use placeholders for secrets; keep real values in gitignored `*.local.*`.
- Ask before any large restructure or destructive rewrite.
- Prefer tool-native hooks / scoped rules / commands for must-happen, path-specific, or on-demand needs.

**DON'T**
- Don't bloat: more lines lower adherence to ALL rules, not just new ones.
- Don't include vague filler ("follow best practices", "be a senior engineer").
- Don't restate what the agent learns by reading code.
- Don't commit secrets or echo secret values.
- Don't maintain N divergent per-tool copies, or assume a prose pointer creates zero drift for import-less tools (use symlink/CI generation).
- Don't use the context file as a linter (offload deterministic style to real linters/formatters).
- Don't silently resolve contradictions or delete/relocate pre-existing content without confirmation.
- Don't assume `@`-imports save context — they expand inline at launch and still cost budget.