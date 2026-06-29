# Agent-Context Bootstrap Playbook

**Purpose.** A single, self-contained, reusable prompt you paste into any AI coding agent (Claude Code, Codex, Cursor, Copilot, Windsurf, Cline, Aider, Gemini CLI, …) — or hand to it as a task. The agent will: **(1) recon** the repository, **(2) detect** whether agent-facing context already exists and which tool/standard is in use, then **(3) branch** — either **CREATE** a fresh thin root context file plus a deep on-demand docs folder, or **MERGE** the proven patterns below into whatever context already exists, **non-destructively**. Goal: leave behind context that makes every future agent faster and less error-prone on this codebase.

This playbook encodes one proven model — a *thin auto-loaded root file* plus a *deep on-demand docs folder*. The reference shape is `CLAUDE.md` + `.claude/`, but the playbook is **tool-agnostic**: the agent first **detects** the tool in use, then creates the matching root file while keeping one shared docs folder.

> **Do NOT hard-code `CLAUDE.md` / `.claude/`.** They are cited only as the reference shape. The agent must DETECT the tool and create the matching root file. Follow the numbered Recon → Detect → Branch flow literally; stop at each gate checklist before proceeding.

> **Tool facts change.** The detection table and anti-patterns below were last verified `(2026-06-26)`. Tool behaviors (which files a tool auto-loads, char caps, frontmatter keys) drift fast. Treat every tool-specific claim as a hypothesis: if the repo already uses a tool, prefer the evidence in-repo; when in doubt, check the tool's current docs rather than trusting this table.

---

## How to use

1. Paste this entire file to the agent as the task (or save it as `bootstrap-agent-context.md` and tell the agent to follow it).
2. The agent runs **Step 0 (Recon)**, fills the **Detection table**, prints the **branch decision with evidence**, then executes exactly one branch: **CREATE** or **MERGE**.
3. The agent **verifies every claim against code** (run/dry-run commands, open referenced files) before writing it.
4. The agent does **not commit** unless you explicitly ask; it ends by emitting the **Output / Report contract**.
5. Tune scope if you want ("skip per-feature docs", "AGENTS.md only"); otherwise it uses the defaults below. Adapt all names to the detected tool.

---

## Core design principles (read first — these justify every template and step below)

Follow the spirit, not just the letter. Each principle states *why* the artifacts look the way they do.

1. **Progressive disclosure: thin auto-loaded root + deep on-demand docs.** The root file is injected into the agent's context *every turn*, so keep it tiny (target **< 150–200 lines**) to protect the token budget — it carries only identity, layout, commands, recipes, and a map that *links out*. All depth (architecture, schema, per-feature rules, troubleshooting) lives in a sibling docs folder the agent opens only when a task touches it, so deep knowledge costs tokens exactly when relevant, never speculatively.
2. **Single source of truth (SoT) per concern.** For each cross-cutting fact (route registry, permission codes, endpoint map, env config, module registry) name the *one* file that owns it and state the mandatory edit order: "X is the SoT for Y; to add/rename, edit X first, then references." This stops duplicate/conflicting definitions that silently drift.
3. **Docs-map table with a 'when to read' column.** Never list bare filenames. Use a 2-column table — link | a *trigger* phrase ("Blueprint convention + error contract", "Symptom → fix steps") — so the agent selects the one right doc in a single pass.
4. **Actionable recipes as numbered checklists + a coupling list.** Encode multi-file tasks (add endpoint, add screen) as ordered, real-path steps, immediately followed by "identifiers that must stay consistent across files." Recipes say what to do; the coupling list says what breaks if a step is half-done.
5. **Safety constraints load every session.** Put danger boundaries in the always-on root: never write to shared/remote DBs without per-action approval; secrets stay in gitignored files (document key names, never values); gate endpoints behind auth + permission; raise the project's typed error, not ad-hoc dicts; use multi-tenant search-path/schema isolation; don't re-save binary design source files through tooling.
6. **Verify, don't trust.** Code is ground truth; docs may lag. Verify every factual claim (command, path, symbol, endpoint, schema, permission) against code before writing it. State the verification method when there's no test suite ("launch app, exercise endpoint"). Link to source files so docs degrade gracefully.
7. **Dated snapshots on volatile facts.** Prefix anything that changes (feature inventory, counts, what's placeholder, current folder contents) with `(YYYY-MM-DD)`. Mark code-derived counts approximate and tell the agent to cross-check the source. Leave durable design rules undated.
8. **Surgical & additive; brevity raises adherence.** Touch only what the task requires; clean up only the orphans your own change creates; match existing voice/structure. Never delete or rewrite working content — *propose* it with evidence. Be command-first, concrete, with verifiable "done" criteria: vagueness — not model limits — is the dominant cause of agents ignoring context.

---

## Step 0 — RECON (always run first; read-only, edit nothing)

Run these in order, then print a findings summary you will cite at the decision gate. **Never** read secret *values* into output — note only their location and required key names.

```
 1. Root & VCS:        confirm repo root + .git; read .gitignore (learn what's excluded);
                       record default/main branch + clean/dirty. Touch nothing while dirty
                       unless told.
 2. Stack & versions:  parse manifests at EVERY level — package.json(+lock), Pipfile/pyproject/
                       requirements, go.mod, Cargo.toml, pom.xml/build.gradle, composer.json,
                       Gemfile, *.csproj. Note pinned runtimes (engines, python_requires, .nvmrc).
 3. Commands:          extract install/build/run/test/lint/format from manifest scripts + CI
                       (.github/workflows, .gitlab-ci.yml, Makefile, justfile, taskfile). Prefer
                       EXISTING commands over inventing. Record exact invocation + working dir.
                       If NO test suite, record how to verify instead (launch + exercise).
 4. Layout:            mono-repo vs single (workspaces, packages/*, multiple manifests); map
                       source vs generated/vendored vs config folders.
 5. Entry points:      server bootstrap (app.py/main.go/index.ts/Program.cs), CLI entry, SPA
                       bootstrap (main.js/ts), and the route/handler/screen registry.
 6. Sources of truth:  route+permission/constant registries, env/settings (+ PRD vs non-PRD
                       selection), central enum/constant modules. These become the
                       "read alongside the docs" files.
 7. Data & services:   DB driver/ORM imports, connection/config, migration + seed/DDL locations,
                       queues, caches, remote services (auth, 3rd-party). Record logical→physical
                       schema map if multi-tenant/multi-schema.
 8. Conventions:       sample several files per layer — naming (tables/endpoints/files/components),
                       folder-per-feature vs layered, error/response contract shape, how a new
                       endpoint/screen is wired end-to-end, lint/format config.
 9. Existing context:  run the DETECTION scan below (fill the table).
10. Secrets handling:  confirm secrets are gitignored; record key NAMES + location only — never
                       read or echo values.
11. Status snapshot:   capture (YYYY-MM-DD) what's fully wired vs placeholder, which commands
                       actually run, obvious doc↔code gaps. This is your verification baseline.
```

### Detection scan — tool → root file → rules dir (scan root AND nested dirs; closest-file-wins)

Glob/ls the repo root **and every monorepo package**, recursing for nested files. Case-insensitive search basenames: `AGENTS`, `CLAUDE`, `GEMINI`, `AGENT`, `CONVENTIONS`, `copilot-instructions`, `cursorrules`, `windsurfrules`, `clinerules`. Plus dir check: `.cursor/ .windsurf/ .clinerules/ .claude/ .gemini/ .github/`.

| Tool / standard | Root file(s) | Rules dir / extras | Detection notes |
|---|---|---|---|
| **AGENTS.md** (open standard, broadly adopted; most portable) | `AGENTS.md` (one per package; closest wins) | none — scope via nested `AGENTS.md` down the tree | Read natively by a growing set of tools (e.g. Codex, Cursor, Copilot/VS Code, Windsurf, Amp, Jules). Coverage varies and grows; verify the specific tool rather than assuming. |
| **Claude Code** | `CLAUDE.md` (project root + any parent), `~/.claude/CLAUDE.md` (user), `CLAUDE.local.md` (deprecated; gitignored) | `.claude/` (`settings.json`, `settings.local.json`, `commands/`, `agents/` (subagents), `skills/`) | Walks up the dir tree and concatenates `CLAUDE.md` files; also reads nested `CLAUDE.md` on demand. Does **NOT** read `AGENTS.md` natively — bridge with an `@AGENTS.md` import line. Grep for `^@\S+\.md` imports and follow them. |
| **Gemini CLI** | `GEMINI.md` (+ `~/.gemini/GEMINI.md`) | none — hierarchical concat by scope (context filename is configurable) | Does not read `AGENTS.md` by default (configurable). Supports `@file.md` imports. |
| **Cursor** | legacy `.cursorrules` (deprecated but still read); also reads `AGENTS.md` | `.cursor/rules/*.mdc` | `.mdc` = optional YAML frontmatter (`description`/`globs`/`alwaysApply`) + body. Plain `.md` in the rules dir is **not** picked up as a rule. |
| **GitHub Copilot** | `.github/copilot-instructions.md`; also reads `AGENTS.md` | `.github/instructions/*.instructions.md` (`applyTo` glob), `.github/prompts/*.prompt.md` | Auto-injected per-repo when repo instructions are enabled. |
| **Windsurf** | legacy `.windsurfrules` (deprecated); also reads `AGENTS.md`/`.cursorrules`/`.clinerules` | `.windsurf/rules/*.md` | Per-rule char caps apply (historically ~6k/rule, ~12k total workspace) — verify current limits. Cascade Memories are local, NOT in VCS. |
| **Cline** | legacy `.clinerules` (single file); also reads `.cursorrules`/`.windsurfrules` | `.clinerules/` (directory: all files combined) | Often paired with `memory-bank/`. |
| **Aider** | `CONVENTIONS.md` (not auto-loaded by default) | `.aider.conf.yml` `read:` entry | Loaded read-only via `/read` or a config `read:` entry. |
| **Generic / fallback** | `README.md`, `CONTRIBUTING.md` | `docs/` (free-form) | Human docs + fallback only. **NOT** proof of dedicated agent context. |

Also glob for other emerging conventions: `.junie/`, `.roo/` / `.roomodes`, `memory-bank/`, and any `*.mdc`/`*.instructions.md` rule files. Parse `.mdc` frontmatter (`description`/`globs`/`alwaysApply`, or `applyTo` for `*.instructions.md`) and follow `@`-imports to map the real instruction graph. If you find a convention not in this table, record it literally and verify against the tool's docs — do not force-fit it.

> **Detection pitfalls:** `AGENTS.md` is *not* universal (Claude Code & Gemini CLI need their own files by default). Scanning only the root misses nested closest-wins files. A stray `README`/`docs/` is human docs, not agent context. Memory features (Cascade/user-memory) are local, not version-controlled.

### Pick the target file convention

- **If a specific tool is clearly in use** (its root file or rules dir exists, or the user names it): create/extend **that tool's** native root file as the thin root.
- **If unknown / multiple / "any agent":** make **`AGENTS.md`** the source-of-truth root (most portable), then add **thin bridges** rather than duplicating — a root `CLAUDE.md` containing an `@AGENTS.md` import line (use the import, **not** a Windows symlink), point `GEMINI.md` at the same content (Gemini does not read `AGENTS.md` by default), Aider `read: AGENTS.md`. Maintain **one** document, not N.
- **Reach for tool-specific glob-scoped files** (`.cursor/rules/*.mdc`, `*.instructions.md` `applyTo`) only when you need that tool's unique auto-attach feature.
- **Shared docs folder is always tool-agnostic:** `.claude/` if Claude Code is primary, else `docs/agent/`. The root file links into it regardless of tool.

---

## Decision gate — does meaningful agent context already exist?

```
IF (no root agent file: AGENTS.md / CLAUDE.md / GEMINI.md / .cursorrules /
    copilot-instructions.md / …)
   AND (no docs folder aimed at agents: .claude/ , docs/agent/ , .cursor/rules/ , …)
        → take the CREATE branch.

ELSE (any dedicated agent context exists, even thin or one tool file)
        → take the MERGE branch. Never clobber.

Edge: only a human README/CONTRIBUTING/docs and NO agent-targeted file → treat as CREATE,
      but mine those human docs as source material and link to them (don't duplicate).
```

Record the decision + the evidence (which files were/weren't found, detected tool(s) + chosen target). Print it before proceeding. Then execute exactly one branch.

---

## BRANCH A — CREATE (no agent context exists)

> Goal: a thin root + a focused docs folder (one file per concern, never one monolith). Verify every claim against code. Present for review; don't commit unless asked.

**Gate checklist before writing**
- [ ] Re-verified no agent-context file exists (else switch to MERGE).
- [ ] Target tool chosen (default `AGENTS.md` + bridges) and docs-folder name chosen (`.claude/`, `docs/agent/`, or tool-native).
- [ ] Recon facts on hand (commands, layout, SoT files, schema map, secrets locations).

### A1. Annotated ROOT file template

Save as the detected tool's root file (`AGENTS.md` default; `CLAUDE.md` if Claude Code). Keep **< ~150 lines**. Replace every `<…>`; delete sections that don't apply. Readable in under a minute.

````markdown
# <Project name>

<One sentence: what this project is + top-level layout.> Detailed architecture, data model,
conventions, and per-feature rules live in [<docs-folder>/](<docs-folder>/) — start at
[<docs-folder>/README.md](<docs-folder>/README.md).

## Repository layout
<Mono-repo? single? List each package/module, its stack, and what it serves.>
- `<pkg-a>/` — <stack, runtime version> — <what it serves>
- `<pkg-b>/` — <stack> — <what it serves>

## Commands
### <pkg-a> (run in `<pkg-a>/`)
```bash
<install>      # e.g. npm ci  /  pipenv sync --dev
<run/dev>      # exact invocation
<build>        # production build
<test>         # or: "No automated tests — verify by <launch app + exercise endpoint>"
<lint> / <format>
```
### Pre-commit hook (run once per clone)
```bash
<one-time hook setup, e.g. git config core.hooksPath .githooks>
```

## Adding work — quick recipes
**New <endpoint>:**
1. Add URL + permission constants to [<SoT file>](...).   ← SoT, edit FIRST
2. Create `<real/path/{__init__,views,validate,query}.py>`.
3. Register in `<module>/app.py` with `@auth_required` + `check_authorization(<PERM_CONST>)`.
Details → [<docs>/architecture/<layer>.md](...).

**New <screen/module>:** <condensed numbered steps, each a real file>. Details → [...](...).

## Docs map
| File | When to read |
|---|---|
| [<docs>/README.md](...) | Docs index + project snapshot — read first |
| [<docs>/architecture/<layer>.md](...) | <trigger: "boot flow, SoT registries, error contract"> |
| [<docs>/db/access.md](...) | <trigger: "query templates, schema map, migrations"> |
| [<docs>/conventions.md](...) | <trigger: "naming, add-a-feature recipes, OS gotchas"> |
| [<docs>/debug-checklist.md](...) | <trigger: "symptom → fix steps"> |

## Notes
- Host/OS: <e.g. Windows → bash syntax + forward-slash paths (/dev/null)>.
- Credentials live in gitignored `<path>` (key names only) — never inline secrets.
- Hook must be enabled or pre-commit formatting won't run.

## Behavioral guidelines (always on)
- Think first: state assumptions; ask when unclear; surface tradeoffs; don't pick silently.
- Simplicity: minimum code that solves it; nothing speculative.
- Surgical: touch only what the request needs; remove only orphans your change created.
- Goal-driven: turn each task into a verifiable success criterion; loop until it passes.
- Safety: NEVER write to shared/remote DB without per-action approval; secrets stay gitignored.
````

### A2. Annotated DOCS-FOLDER layout + per-file skeletons

```
<docs-folder>/
  README.md            ← index: snapshot + docs-map + read-order + source-files list
  architecture/
    <layer-a>.md        (e.g. server.md): boot flow, layout, SoT registries, error contract
    <layer-b>.md        (e.g. client.md): boot flow, endpoint map, store/module registry
    <cross-cutting>.md  (e.g. auth-and-tenant.md): auth, authorization, tenant isolation
  db/ (or data.md)
    access.md           query templates (NO credentials)
    schemas.md          schema list + logical→physical map
    credentials.local.md   ← GITIGNORED; key names only
  conventions.md        naming, folder-per-feature, end-to-end recipes, lint/format, OS notes
  reference/            mechanical lookup tables (regenerable), separate from prose
    endpoints.md  permissions.md  <enums>.md     — dated/approximate
  screens/ (or features/)
    overview.md         table: each WIRED feature → pattern + status
    <feature>.md        one per WIRED feature only
  debug-checklist.md    symptom → ordered checks → link to explaining doc
  *.local.md            GITIGNORED host-specific / credential notes
```

**`README.md` (docs index) — the declared "read first":**
```markdown
# <Project> — Agent Docs Index

## Project snapshot (YYYY-MM-DD)
<What exists vs placeholder, e.g. "Six screens wired; i02/ and i05/ are placeholders.">
<Volatile facts get the date prefix; code-derived counts marked approximate.>
- Stack: <…>. Mono-repo: <yes/no>. Verify method: <tests | launch & exercise>.

## Docs map
| File | When to read |
|---|---|
| [architecture/<layer>.md](...) | <trigger> |
| [reference/endpoints.md](...) | <"exact endpoint name lookup"> |
| [conventions.md](...) | <trigger> |
| [debug-checklist.md](...) | <"symptom → fix", only when debugging> |

## Read order for new agents
1. Root <CLAUDE.md/AGENTS.md> (quick ref)
2. This README (index + snapshot)
3. architecture/<high-level layer>.md
4. architecture/<auth/tenant/data model>.md   ← the model everything depends on
5. conventions.md
6. screens/features as the task touches them
7. reference/* (lookup as needed)
8. debug-checklist.md (only when debugging)

## Source files to read alongside the docs
- `<entry point>` · `<route/permission registry SoT>` · `<settings/env>` ·
  `<auth helper>` · `<DB helper>` · `<SPA boot>` · `<endpoint map>` · `<store index>`

> Note: personal/auto-memory may live OUTSIDE the repo (gitignored / agent home) — it
> exists but is NOT version-controlled.
```

**`architecture/<layer>.md` skeleton:**
```markdown
# <Layer> architecture
## Stack & versions
| Component | Version | Notes |
|---|---|---|

## Boot flow
<entry point → registration → request lifecycle, each step naming a real file.>

## Single sources of truth
- **<Routes/constants>** → `<file>`. To add/rename: edit `<file>` FIRST, then references.
- **<Endpoint map>** → `<file>`. **<Module/store registry>** → `<file>`.

## Error / response contract
| Raised | HTTP | Client effect |
|---|---|---|
| `ApiError(code, message_id, status)` | <status> | <dialog/code> |
→ Raise the typed error, not ad-hoc dicts, so the global handler + client stay consistent.
```

**`conventions.md` skeleton:** naming patterns (tables/endpoints/files/components) · folder-per-feature vs layered · **end-to-end "add a feature" recipe** (real paths) · **coupling that must stay consistent** (identifiers that must match across view/store/api/schema/setting; where each lives) · lint/format config · spec→code workflow (classify behavior as *in-contract* vs *UI-only*; trace every conclusion to a source location) · host/OS pitfalls.

**`reference/<x>.md` skeleton:** a single table of exhaustive name/value inventory, prefixed `(YYYY-MM-DD)`; note when counts are approximate/code-derived and that the agent should cross-check the source (e.g. "34 folders but 33 URLs — explain why").

**`screens/overview.md` skeleton:**
```markdown
| Feature | Pattern used | Status (YYYY-MM-DD) |
|---|---|---|
| <I01-04> | <CRUD master / custom> | wired |
| <I02-xx> | — | placeholder (don't document) |
```

**`debug-checklist.md` skeleton:**
```markdown
## Symptom: <route missing from UI>
- [ ] <Is X registered in the SoT? Does appkn_id match between backend and ROUTE_DEFINITIONS?>
- [ ] <Does screen_code match across view/store/api/schema/setting?>
→ See [architecture/<layer>.md](...).

## Symptom: <401 empty body> / <wrong-tenant data> / <typed-error dialog code>
- [ ] <Is the token set?  Is SET SEARCH_PATH TO {schema} prepended?  …>
```

### A3. CREATE steps

```
1. Re-verify no agent context exists (else switch to MERGE).
2. Draft the thin ROOT (A1) for the detected tool; add thin bridges if "any agent".
3. Create the docs folder; one focused file per concern (A2) — not one monolith.
4. Fill architecture / db-data / conventions / reference — every claim traced to a named file.
5. Add credentials.local.md (gitignored, key names only); ensure .gitignore covers *.local.md.
6. Write per-feature docs ONLY for wired features; add the overview table with dated status.
7. Write debug-checklist from real failure modes visible in code/config; mirror critical couplings.
8. Write the README index (snapshot + docs-map + read-order + source-files list), all dates stamped.
9. VERIFY: run/dry-run every documented command; open every referenced file/symbol; date every snapshot.
10. Run the Acceptance checklist; revise until it passes. Present for review (don't commit unless asked).
```

---

## BRANCH B — MERGE (agent context already exists)

> Goal: fold the proven strengths above into the existing context **without** clobbering it. Read everything first; preserve the authors' voice and structure; change only what's missing or code-verified-stale. **Add > rewrite; correct only code-verified falsehoods; propose deletions, don't delete.**

### B1. Inventory & reconstruct the existing workflow
- Read **fully** every existing context file (root, docs folder, scattered READMEs/CONTRIBUTING, tool-specific rule files) before editing anything.
- Reconstruct the **style contract**: intended read-order, file granularity, tone (terse vs prose), language, table-vs-prose style, link conventions, where status snapshots live. You must preserve this.

### B2. Build the ideal-target model + gap analysis
Build the ideal target (thin root + architecture + db/data + conventions + reference + per-feature + debug-checklist + indexed README with docs-map & read-order) and map existing files onto it. Mark what's already adequate and leave it alone. Check the gaps:

```
[ ] Thin root AND a separate detailed docs folder — or is everything crammed in one place?
[ ] README index has a docs-map with a 'when to read' column AND an explicit read-order?
[ ] Architecture / db-data / conventions / reference / per-feature / debug-checklist all present
    (not merged ambiguously)?
[ ] Documented build/run/test/lint/format commands still execute as written, in the stated dir?
[ ] Referenced files/symbols/endpoints/schemas/permissions still exist with current names?
[ ] Status snapshots present + dated + reflect current built-vs-placeholder reality?
[ ] Credentials kept out of VCS (key names only)?
[ ] Docs cover features that exist while avoiding documenting unbuilt ones?
[ ] Is the root still short, or has detail leaked in that belongs in the docs folder?
```

### B3. Detect drift / stale claims
Verify each factual statement against current code: commands that no longer run, renamed files/symbols, endpoints/screens added or removed, schema changes, snapshots whose date no longer matches reality. Flag each as **confirmed-stale** vs **uncertain**.

### B4. Classify & apply (in this order of safety)
```
ADDITIVE     → new file or appended section, in the existing style. Insert into the read-order
               + docs-map. Do NOT reflow surrounding working content.
CORRECTION   → only for claims VERIFIED false against code. Minimal wording change; refresh the
               associated snapshot with today's date + verified facts. Leave UNCERTAIN claims in
               place and raise them as questions.
RESTRUCTURE  → moving content, stale-but-load-bearing text, or any deletion: DO NOT delete in
               place. Propose explicitly (what / why / evidence); leave the working doc intact
               until approved.
```

### B5. Non-destructive rules (hard constraints)
- Preserve voice, language, structure, formatting. Every changed line traces to a missing section or a code-verified stale claim — no reformatting "improvements".
- Never wholesale-rewrite or delete a working doc; propose with evidence and wait.
- Don't impose a new read-order scheme, don't move secrets into tracked files, don't bloat the root.
- Keep snapshots append-or-update with today's date; don't erase historical context without approval.

### B6. Finish
Update the README index so new/changed docs appear in the docs-map, 'when to read', and read-order (keeping existing ordering logic). Re-verify the whole set against code one final pass; ensure all snapshots are dated. Run the Acceptance checklist. Produce the change summary (added / corrected / proposed-for-deletion). Commit only if asked.

---

## Acceptance checklist (both branches)

```
[ ] Took exactly ONE branch (CREATE or MERGE), with the decision + evidence printed.
[ ] Every factual claim (commands, paths, symbols, endpoints, schemas, permissions) verified
    against actual code — not memory.
[ ] All documented build/run/test/lint/format commands execute as written from the stated dir.
[ ] Root file is thin: quick-ref + recipes only, readable in under a minute, all detail delegated.
[ ] Docs-folder README exists: dated snapshot + docs-map (with 'when to read') + numbered
    read-order + source-files-to-read-alongside list.
[ ] Ideal concern set covered as focused files (architecture, db/data, conventions, reference,
    per-feature, debug-checklist) — not one monolith.
[ ] Every status/coverage snapshot carries an ISO date + reflects current built-vs-placeholder
    reality.
[ ] No doc describes unbuilt/removed functionality; built features that exist are documented.
[ ] Credentials/secrets gitignored; only key names + locations documented, never values.
[ ] Detected tool's actual auto-load convention used (right filename + dir + frontmatter); any
    tool-specific claim either verified in-repo or against current tool docs.
[ ] MERGE only: existing voice/structure/read-order preserved; changes are surgical additions or
    code-verified corrections; no working doc rewritten/deleted without an explicit proposal.
[ ] Links between root, README index, and docs resolve; read-order is consistent with the docs-map.
[ ] A reviewer-facing change summary produced; nothing committed unless the user asked.
```

---

## Anti-patterns (do NOT do these)

- **Assuming `AGENTS.md` is universal.** Claude Code reads it only via an `@AGENTS.md` import; Gemini CLI doesn't read it by default (wants `GEMINI.md`). Detection must not stop at the root or at one file.
- **Plain `.md` in `.cursor/rules/`** — not picked up as a rule (Cursor rules are `.mdc` with optional frontmatter). Use `.mdc`, or put plain markdown in `AGENTS.md`.
- **Overusing always-on / `alwaysApply: true`, or letting files bloat** — burns the instruction budget every turn and lowers adherence.
- **Maintaining N divergent files** (`CLAUDE.md`, `.cursorrules`, `copilot-instructions.md`, `GEMINI.md`) that drift out of sync — converge on one SoT (`AGENTS.md`) + thin bridges.
- **Symlinking `AGENTS.md`→`CLAUDE.md` on Windows** — needs Admin/Developer Mode and can fail; use an `@AGENTS.md` import line instead.
- **Scanning only the root** — misses nested closest-file-wins context.
- **Ignoring per-rule char caps** (e.g. Windsurf) — over-long rules can get truncated; verify the current limit.
- **Committing secrets or machine-specific paths** into shared context — keep in gitignored local files.
- **Confusing memory features with rules** — Cascade/user-memory are local, not VCS, won't reach teammates/CI.
- **Treating README/docs as agent-context** — they're human-facing fallback, not proof.
- **Vague, prose-heavy instructions with no exact commands or verifiable success criteria** — the dominant real-world cause of agents ignoring project context.
- **Documenting unbuilt features, undated volatile facts, duplicating the human README, or treating code-derived counts as exact.**
- **Re-saving binary spec/design files through tooling** for analysis (can drop shapes/images) — read non-destructively.
- **Deleting/rewriting working docs in MERGE** instead of proposing with evidence.
- **Trusting this table's tool facts as permanent** — they drift; verify against in-repo evidence or current tool docs.

---

## Output / Report contract (agent must end with this — do not commit unless asked)

After running, the agent reports — and commits **only** if the user asked. All file paths must be absolute.

```
BRANCH TAKEN: CREATE | MERGE
EVIDENCE: <files found / not found that drove the decision>
TARGET TOOL & ROOT FILE: <e.g. AGENTS.md (+ CLAUDE.md bridge @AGENTS.md) | CLAUDE.md | GEMINI.md>

FILES CREATED (CREATE):
  - <absolute/path> — <one line: what it is>

FILES CHANGED (MERGE), grouped:
  ADDED      - <absolute/path> — <new file/section>
  CORRECTED  - <absolute/path> — <claim, was → now, with the source that proves it>
PROPOSED FOR DELETION / RESTRUCTURE (NOT applied; awaiting approval):
  - <absolute/path> — <what / why / evidence>

VERIFICATION:
  - Commands run/dry-run: <list + pass/fail>
  - Referenced files/symbols opened & confirmed: <count / notes>
  - Snapshots dated: <YES, YYYY-MM-DD>

OPEN QUESTIONS / UNCERTAIN CLAIMS (left in place, flagged):
  - <question for the user>

ACCEPTANCE CHECKLIST: <all passed? else what remains>
COMMITTED: NO (unless user requested) | <branch/commit ref>
```
