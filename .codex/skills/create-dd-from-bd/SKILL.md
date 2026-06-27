---
name: create-dd-from-bd
description: Create or update NanoBio module DD files from a user-provided BD, BRD, product flow, or business request using the project DD guide and templates.
---

# Create DD From BD

Project-local skill for turning a NanoBio business design source into an implementation-ready DD module.

## When To Use

Use this skill when the user asks to create, scaffold, update, or review a DD from a BD/BRD/product-flow request, especially phrases like "tao DD tu BD", "create DD based on BD", "module DD", "design document from business flow", or "implementation-ready DD".

Do not use this skill for runtime coding by itself. After the DD is accepted, switch to the normal `coding` workflow.

## Required Context

1. Confirm the current workspace is `nano_app`.
2. Read `.codex/workflows/docs-dd.md` and `.codex/task-skills/docs-dd.md` if it exists.
3. Read the user-provided BD/BRD path. If the user gives only a module name, search `docs/BD/` with targeted `rg` and ask only when multiple plausible sources remain.
4. Read `docs/DD/DD_Module_Creation_Guide_EN.md`.
5. Read `docs/DD/DD_Module_Template/README.md`, then read only the template files that will be created or changed.
6. Read `references/dd-module-from-bd.md` before writing DD files.
7. Read related DDs, schemas, source code, issues, or worklogs only when they are required to resolve dependencies or prove traceability.

## Output Contract

Create or update one module folder under `docs/DD/`. Use the exact target path requested by the user when provided; otherwise derive a stable lowercase folder name from the BD module name and keep it consistent across all DD files.

The module folder should contain:

- `README.md`
- `Overall.md`
- `List_Features.md`
- `Function_List.md`
- `Views.md`
- `Import_File.md`
- `diagrams/README.md`
- the module-level assets README
- `history/CHANGELOG.md`

Preserve template intent, but replace all placeholders with module-specific content or explicit markers.

## DD Rules

- Every DD fact must trace to a BD heading, BD ID, requirement, acceptance criterion, source path, or explicit user instruction.
- Do not invent missing business behavior. Use `OPEN QUESTION`, `ASSUMPTION`, or `PROPOSAL` markers when the BD is incomplete.
- Use stable IDs for traceability: `<MODULE>-Fxx`, `<MODULE>-FNxx`, `<MODULE>-Vxx`, `<MODULE>-BRxx`, `<MODULE>-APIxx`, `<MODULE>-E-...`, `<MODULE>-ADRxx`, and `<MODULE>-TCxx`.
- Separate business decisions from implementation proposals.
- Keep user-facing copy Vietnamese when the DD defines app UI text, but keep agent context and meta instructions in English.
- Do not modify runtime code as part of this skill unless the user explicitly asks for implementation after the DD work.

## Completion

After editing DD files:

1. Update or create a worklog under `docs/worklog/<local-date>/`.
2. Run `powershell -ExecutionPolicy Bypass -File .codex/tools/update_worklog_learning.ps1`.
3. Run `powershell -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1`.
4. Run `git diff --check`.
5. Report the DD module path, open questions, assumptions, and validation status.
