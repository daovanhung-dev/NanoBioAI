Commit de xuat: docs(context): bootstrap agent context merge

# Worklog - Agent context bootstrap merge

## Thoi gian

- Ngay: 2026-06-30
- Bat dau: 20:00
- Ket thuc: 20:17
- Timezone: Asia/Saigon

## Pham vi

- Loai task: docs-context
- Module chinh: `.codex`, agent context, docs integrity
- Yeu cau goc: Execute `docs/prompts/bootstrap-ai-context.md` as a merge pass, keep root `AGENTS.md` as bridge, keep `.codex/AGENTS.md` canonical, avoid unused tool fan-out, fix current context validation blocker, and refresh history learning.

## Da lam

- Added a compact command-first table to `.codex/AGENTS.md`.
- Added a docs/context-only validation recipe and noted why broad runtime quick checks are not the default for docs-only work.
- Replaced stale `.codex/Design.md` Appendix F asset rows with the current asset tree and dated the snapshot.
- Preserved existing root `AGENTS.md`, `.agents/skills/*` bridges, and prompt-file worktree changes outside this scope.

## File code/docs da sua

- `.codex/AGENTS.md` - sua - add exact commands and docs-context validation guidance.
- `.codex/Design.md` - sua - replace stale asset map paths that broke integrity validation.
- `docs/worklog/2026-06-30/007-worklog-agent-context-bootstrap.md` - tao - record this context update.
- `.codex/history/LEARNED_SKILLS.md` - generated - refresh worklog learning after this worklog.
- `.codex/history/RISK_HISTORY.md` - generated - append extracted evidence from this worklog.
- `.codex/history/WORKLOG_INDEX.md` - generated - add this worklog to the index.
- `.codex/task-skills/README.md` - generated - update docs-context worklog count.
- `.codex/task-skills/docs-context.md` - generated - update docs-context summary from the new worklog.

## Tai lieu lien quan

- `docs/prompts/bootstrap-ai-context.md`
- `AGENTS.md`
- `.codex/AGENTS.md`
- `.codex/workflows/docs-context.md`
- `.codex/task-skills/docs-context.md`
- `.codex/history/SESSION_QUALITY_REVIEW.md`

## Commands

- `powershell -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1`: PASS - integrity validation passed after asset map cleanup.
- `git diff --check`: PASS - no whitespace errors; Git warned that LF may be replaced by CRLF for touched `.codex` files.
- `rg -n "Docs/context-only recipe|Docs/context validation|Quick runtime check|Snapshot 2026-06-30|assets/animations|assets/audio|assets/fonts|assets/illustrations|assets/json|assets/svg|assets/translations|assets/videos" .codex/AGENTS.md .codex/Design.md`: PASS - new markers present; stale asset groups absent from the checked files.
- `powershell -ExecutionPolicy Bypass -File .codex/tools/update_worklog_learning.ps1`: PASS - refreshed history and canonical task-skills from 56 worklog files after creating and finalizing this worklog.

## Loi/Rui ro

- Da fix: `.codex/tools/validate_codex_integrity.ps1` failed before this session because `.codex/Design.md` referenced removed asset directories/files.
- Chua fix: none in this scope.
- Can kiem tra tiep: none in this docs-context scope.

## Ty le hoan thanh

- Hoan thanh: context merge edits, history refresh, integrity validation, diff check, targeted `rg`, and final status review.
- Dang do: none.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - changes are scoped to agent context and validation blocker.
- Muc do hoan thanh task: complete for the requested docs-context scope.
- Bang chung kiem chung: integrity validation PASS, `git diff --check` PASS, targeted `rg` PASS, history refresh PASS.
- Diem ton token/chua toi uu: did not read broad source, tests, all DD, raw worklogs, or `.codex/MAP_TREE.md`; used targeted context and asset inventory.
- Cach toi uu cho phien sau: for docs-context work, read `.codex/workflows/docs-context.md`, `.codex/task-skills/docs-context.md`, then inspect only the failing context file and validation script output.
- Task-skill can doc lan sau: `.codex/task-skills/docs-context.md`
