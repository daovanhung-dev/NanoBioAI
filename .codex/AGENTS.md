# AGENTS - NanoBio / BioAI

Entrypoint canonical cho Codex trong repo nay. Root `AGENTS.md` chi la bridge auto-discovery va phai tro ve file nay. Muc tieu: chon dung workflow, doc dung domain, giu kien truc va cap nhat history sau moi phien co worklog.

## Snapshot

- App: NanoBio / NamiAI - tro ly suc khoe AI bang Flutter.
- Persona UI: Nabi- am ap, nhe nhang, quan tam, khong phan xet.
- Kien truc: feature-first + Clean Architecture theo code hien co.
- Stack: Flutter/Dart SDK `^3.9.2`, Riverpod `3.3.1`, GoRouter `17.2.3`, sqflite `2.4.2`, Supabase `2.12.4`, Gemini SDK `0.4.7`, local notifications `19.5.0`.
- SQLite version: `DatabaseVersion.currentVersion = 8`.
- Source version: `v1` guest/basic, `v2` authenticated free, `v3` Plus/FamilyPlus planned, `sale_referral` independent.

## Required Read Pack

Always start with:

1. `.codex/PROJECT_MAP.md`
2. `.codex/history/LEARNED_SKILLS.md`
3. One workflow from `.codex/workflows/`
4. Matching `.codex/task-skills/<task-key>.md` if it exists
5. One domain from `.codex/domains/` when task touches code/product

If the user only asks to read context and does not name a work type, read `.codex/workflows/context-read.md`, `.codex/workflows/README.md`, `.codex/domains/README.md`, `.codex/task-skills/README.md`, and `.codex/history/WORKLOG_INDEX.md`.

Do not read `.codex/MAP_TREE.md`, `.codex/history/RISK_HISTORY.md`, raw `docs/worklog/**/*.md`, raw `lib/**`, raw `test/**`, or all `docs/DD/**` by default. Open them only when the selected workflow requires exact inventory, historical evidence, source inspection, tests, or DD details.

## Workflow Router

Use `.codex/workflows/README.md` to choose the primary workflow:

- `context-read`: read `.codex` or project context.
- `coding`: implement feature/change.
- `bugfix`: fix a concrete bug without existing issue/todo.
- `fix-issues`: fix a documented issue through todo.
- `test`: run or document tests; do not fix code.
- `find-issues`: audit/review and write issue docs.
- `create-issues`: convert findings into issue docs.
- `create-todo`: convert issue docs into todo docs.
- `docs-dd`: create/update/read DD from BD.
- `docs-context`: update `.codex`, maps, checklists, project docs.
- `refactor-scaffold`: restructure version/module scaffolds.
- `supabase-schema`: SQL/RLS/membership/quota/family/sale docs.

Do not mix modes unless the user explicitly asks for a chain.

## Task Skill Router

After choosing the workflow, read `.codex/task-skills/README.md` and then the matching task file if present. If no exact task key exists, continue with the workflow and record the missing/needed task-skill in the worklog self-review.

Before expanding context, ask and answer: how can this task use fewer tokens while producing equal or better work? Prefer router files, indexes, `rg`, and targeted file reads before raw directories, raw worklogs, all DD files, or broad test output.

Read `.codex/history/OPEN_RISKS.md` only when the task touches release readiness, auth, Supabase, DD status, or testing.

## Domain Router

Use `.codex/domains/README.md` and read one domain file by default:

- Dashboard/health score/home
- Onboarding/profile assessment
- AI/meal/exercise/chat
- Access/auth/membership/referral
- Notification/reminder/action
- SQLite/DAO/migration
- UI/theme/Nabicopy
- Daily health tracking
- Lifestyle schedule/timeline

Add a second domain only after `rg` proves cross-domain impact.

## Architecture Rules

Target dependency flow:

```text
Presentation -> Provider/Controller -> Repository -> Datasource -> DAO/API
```

- UI calls provider/controller, not DB/API directly.
- Presentation must not import DAO, datasource, SQLite model, or `core/storage/localdb`.
- Provider/controller must not call DAO/API directly when repository exists.
- Repository impl calls datasource; datasource calls DAO/service.
- Domain entity/service should stay Dart-pure when possible.
- Follow existing repo pattern when a legacy `RepositoryImpl` lives in `domain/repositories`.
- Do not add production mock/fake/sample data.
- Do not hard-code secrets/API keys or modify real `.env` unless explicitly requested.
- Avoid `dynamic`, `!`, and `as` unless safety is proven.

## Product Flow Guardrails

Critical flow to preserve:

```text
Guest opens app
-> onboarding saves local profile data
-> AI creates the initial personal schedule once
-> meal/task/schedule data saves to SQLite
-> notifications are scheduled with complete/skip actions
-> guest uses only v1 basic modules
-> login/sign-up reads membership from Supabase
-> access gate enables free/Plus/FamilyPlus features
-> dashboard reads real data and recalculates progress
```

Access rules:

- v1 guest/basic: onboarding, basic health modules, first AI personal schedule, local notifications.
- v2 free: authenticated flow, AI chat 3/day, schedule generation 3/month, health score from schedule completion history.
- v3 Plus/FamilyPlus: planned paid features only when BD/DD is ready.
- Sale/referral: independent role; not a membership tier.
- Membership, quota, sale status, referral tree, payment success, and commission must come from Supabase/trusted backend.

## UI And Copy

- User-facing text must be Vietnamese with Nabitone.
- Do not expose internal terms: database, table, query, parser, exception, stack trace, log, tier, entitlement, gate, webhook.
- Prefer tokens in `lib/core/theme/`.

## Validation

Quick check:

```powershell
powershell -ExecutionPolicy Bypass -File .codex/tool/codex_quick_check.ps1
```

Full/native check:

```powershell
powershell -ExecutionPolicy Bypass -File .codex/tool/codex_check.ps1 -BuildApk
```

Docs/context-only changes use `rg` checks and `git diff --check`; do not run Flutter checks unless runtime code changed.

## Worklog And History

Follow `.codex/DOCS_WORKFLOW.md` for docs/worklog. After any worklog update, run:

```powershell
powershell -ExecutionPolicy Bypass -File .codex/tools/update_worklog_learning.ps1
```

This keeps `.codex/history/` as the project memory for future agents.

Every substantial worklog must include the self-review from `.codex/history/SESSION_QUALITY_REVIEW.md`: output quality, completion, verification evidence, token waste, and next-session optimization. The refresh script uses that history to regenerate `.codex/task-skills/*.md`.
