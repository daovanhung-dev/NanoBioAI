Commit proposal: docs(context): add DD from BD project skill

# Worklog - Create DD From BD Skill

## Time

- Date: 2026-06-28
- Start: 00:02
- End: 00:06
- Timezone: Asia/Saigon (+07:00)

## Scope

- Task type: docs-context
- Main module: `.codex/skills/create-dd-from-bd`, `.agents/skills/create-dd-from-bd`, `docs/DD`
- Original request: Read `docs/DD/*` and add skills for creating DD from user-requested BD sources.

## Done

- Read the current DD guide and template files under `docs/DD/`.
- Added canonical project skill `.codex/skills/create-dd-from-bd/SKILL.md`.
- Added detailed DD-from-BD reference `.codex/skills/create-dd-from-bd/references/dd-module-from-bd.md`.
- Added `.agents/skills/create-dd-from-bd/` discovery bridge.
- Updated the DD workflow, project router skill, context router, `.codex/AGENTS.md`, and `.codex/MAP_TREE.md` so agents can discover the new skill.
- Updated `.codex/PROJECT_MAP.md` to point DD routing at the live DD guide/template instead of deleted DD folders.
- Updated `.codex/tools/update_worklog_learning.ps1` so generated history/task-skill summaries strip Markdown code spans from historical module fields and do not treat deleted historical DD paths as live path assertions.

## Files Changed

- `.codex/skills/create-dd-from-bd/SKILL.md` - created.
- `.codex/skills/create-dd-from-bd/references/dd-module-from-bd.md` - created.
- `.codex/skills/create-dd-from-bd/agents/openai.yaml` - created.
- `.agents/skills/create-dd-from-bd/SKILL.md` - created.
- `.agents/skills/create-dd-from-bd/agents/openai.yaml` - created.
- `.codex/workflows/docs-dd.md` - updated.
- `.codex/skills/nanobio-project-agent/SKILL.md` - updated.
- `.codex/skills/nanobio-project-agent/references/context-router.md` - updated.
- `.codex/AGENTS.md` - updated.
- `.codex/MAP_TREE.md` - updated.
- `.codex/PROJECT_MAP.md` - updated.
- `.codex/tools/update_worklog_learning.ps1` - updated.
- `docs/worklog/2026-06-28/001-worklog-create-dd-from-bd-skill.md` - created.

## Related Documents

- `docs/DD/DD_Module_Creation_Guide_EN.md`
- `docs/DD/DD_Module_Template/README.md`
- `docs/DD/DD_Module_Template/Overall.md`
- `docs/DD/DD_Module_Template/List_Features.md`
- `docs/DD/DD_Module_Template/Function_List.md`
- `docs/DD/DD_Module_Template/Views.md`
- `docs/DD/DD_Module_Template/Import_File.md`
- `docs/DD/DD_Module_Template/diagrams/README.md`
- `docs/DD/DD_Module_Template/assets/README.md`
- `docs/DD/DD_Module_Template/history/README.md`

## Commands

- `python C:\Users\daohu\.codex\skills\.system\skill-creator\scripts\quick_validate.py .codex/skills/create-dd-from-bd`: PASS.
- `python C:\Users\daohu\.codex\skills\.system\skill-creator\scripts\quick_validate.py .agents/skills/create-dd-from-bd`: PASS.
- `powershell -ExecutionPolicy Bypass -File .codex/tools/update_worklog_learning.ps1`: PASS - refreshed generated history/task-skills from 35 worklogs.
- `powershell -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1`: PASS.
- `git diff --check`: PASS - no whitespace errors; Git reported line-ending normalization warnings only.
- `rg "create-dd-from-bd|DD_Module_Creation_Guide_EN|DD_Module_Template" AGENTS.md .agents .codex docs/worklog/2026-06-28`: PASS - new routing references found.

## Risks

- Existing deleted tracked files under `docs/DD/product_flow/` were not restored or removed; they pre-existed this session and remain outside this change.
- Generated history still mentions old `docs/DD/product_flow` paths as plain historical evidence, but they are no longer emitted as live backticked paths that fail integrity validation.

## Completion

- Complete: DD-from-BD skill and discovery bridge were added.
- Complete: validation commands passed after generated context cleanup.

## Session Self-Review

- Output quality: focused project skill that routes future DD creation through the current guide and template.
- Completion: complete for context and skill creation; no runtime code touched.
- Verification evidence: skill validation, worklog learning refresh, `.codex` integrity validation, targeted `rg`, and `git diff --check` all passed.
- Token waste: avoided reading raw source or deleted DD trees; read only current `docs/DD` guide/template files and relevant context routers.
- Next-session optimization: if DD-from-BD requests repeat, consider adding helper scripts to scaffold the required DD module folder from the template after the skill proves stable.
