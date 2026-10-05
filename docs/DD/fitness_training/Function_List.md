# Function List — M32 / Chế độ luyện tập

## Function registry

| ID | Function | Runtime source | Current behavior |
|---|---|---|---|
| M32-FN01 | Review profile and check age | `presentation/fitness_training_page.dart`, `domain/services/fitness_training_age_gate.dart`, `application/fitness_training_controller.dart` | Uses full self-declared DOB locally; blocks missing, future or under-18 date. This is pilot-only and spoofable. |
| M32-FN02 | Load and filter catalog | `data/datasources/fitness_training_catalog_asset_datasource.dart`, `domain/entities/fitness_training_catalog.dart` | Loads bundled catalog; filters by home/gym, selected equipment, movement exclusions, food groups and allergens. |
| M32-FN03 | Generate 28-day program | `application/fitness_training_service.dart`, `data/datasources/fitness_training_local_datasource.dart` | M02 quota check, bounded catalog prompt through the current Gemini backend, strict local validation, then persist a preview. |
| M32-FN04 | Preview and apply a program week | `presentation/fitness_training_page.dart`, `data/datasources/fitness_training_local_datasource.dart` | User confirms; SQLite transaction applies only the selected seven-day window and replaces future incomplete M32 schedule rows. |
| M32-FN05 | Weekly check-in and replan | `application/fitness_training_service.dart`, `presentation/fitness_training_page.dart` | Check-in scores 1–5; Member replan consumes one M02 generation, validates remaining weeks and requires confirmation. Guest replan is unavailable. |

## M32-API01 — Gemini generate operation

Transport: existing `NabiAiBackendClient` and `nabi-ai-generate` Edge Function. Operation: `fitness_training_generate`. The Edge Function retains `GEMINI_API_KEY`, enforces its operation allowlist, request size and rate limit, and returns the provider response. The app checks M02 before calling Gemini. Request contains the minimal intake choices/derived M04 metrics and only prefiltered exercise/recipe catalog IDs. It excludes DOB, name, notes and direct profile measurements. Response must contain exactly the supported program schema and catalog IDs; malformed or out-of-filter output is discarded.

## M32-API02 — Gemini remaining-week replan

Transport: same backend, operation `fitness_training_replan`. Request adds the selected program window and effort/soreness scores; it contains no free-text note. Member calls pass M02 quota checks. Guest is blocked from replan. Output is a preview for the remaining days; applying it requires a second user confirmation.

## Validation and transaction

1. Validate self-declared local adult eligibility and request identity.
2. For Member, require the current authenticated user and M02 quota decision. For Guest, preflight the one-time initial-plan allowance before AI; consume it atomically with valid preview persistence.
3. Filter the static catalog before constructing the bounded AI context.
4. Parse only the exact supported response keys; validate day count/index, rest-day schedule, catalog IDs, selected equipment, movement restrictions, allergens, meal slots, servings and exercise bounds.
5. Save a preview only after the entire response validates.
6. On user confirmation, transactionally persist active program state and replace only future incomplete M32 workout/meal/sleep entries in the local 7-day schedule. Completed, past and unrelated schedule rows remain.
7. Request existing M05 snapshot synchronization after local commit. Current cloud schema is self-subject only; FamilyPlus dependent subjects are outside this pilot implementation.

## Error contract

| Condition | Behavior |
|---|---|
| AGE_NOT_ELIGIBLE / AGE_UNVERIFIED | Block before quota and AI; DOB remains local. |
| QUOTA_EXCEEDED | Do not call AI; preserve current program and schedule. |
| INVALID_CATALOG_REFERENCE / INVALID_PROGRAM | Discard the whole result; do not persist or apply it. |
| AI/network failure | Preserve active program/schedule; retry is keyed by the request ID locally. |
| GUEST_INITIAL_PLAN_USED | Do not call AI; preserve current state. |
| SCHEDULE_APPLY_FAILED | Local transaction rolls back; retry only after reloading current state. |

The Edge Function has operation/rate-limit tests; it does not independently enforce M02 quota or validate catalog semantics. Sandbox review must confirm whether server-side quota enforcement is required before production release.
