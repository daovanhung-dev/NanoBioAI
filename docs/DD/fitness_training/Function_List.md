# Function List — M32 / Chế độ luyện tập

## Function registry

| ID | Function | Runtime source | Current behavior |
|---|---|---|---|
| M32-FN01 | Review profile and check age | `presentation/fitness_training_page.dart`, `domain/services/fitness_training_age_gate.dart`, `application/fitness_training_controller.dart` | Uses full self-declared DOB locally; blocks missing, future or under-18 date. Pilot-only and spoofable. |
| M32-FN02 | Load and filter workout catalog | `data/datasources/fitness_training_catalog_asset_datasource.dart`, `domain/entities/fitness_training_catalog.dart` | Filters exercises by home/gym, selected equipment and movement exclusions. Food and sleep profile data are outside this flow. |
| M32-FN03 | Generate 28-day workout program | `application/fitness_training_service.dart`, `domain/services/fitness_program_validator.dart` | Checks upcoming workout slots before quota/AI. On conflict, proposes the nearest option free on every selected date and requires one-time user consent before M02/AI; refusal/no available time has no quota, AI or write side effect. |
| M32-FN04 | Preview and apply a program week | `presentation/fitness_training_page.dart`, `data/datasources/fitness_training_local_datasource.dart` | User confirms; transaction rechecks time overlaps before mutation and replaces only future incomplete M32 `routine` rows. A stale conflict rolls back, triggers a fresh proposal/consent and needs apply confirmation again; preview time changes do not call AI. |
| M32-FN05 | Weekly check-in and replan | `application/fitness_training_service.dart`, `presentation/fitness_training_page.dart` | Checks upcoming workout conflicts before saving check-in, quota or AI. A conflict needs one-time consent for the suggested time. Member replan consumes M02, validates remaining workout days and requires confirmation. Guest replan is unavailable. |

## M32-API01 — Gemini generate operation

Transport: existing `NabiAiBackendClient` and `nabi-ai-generate` Edge Function. Operation: `fitness_training_generate`. The Edge Function retains `GEMINI_API_KEY`, enforces its operation allowlist, request size and rate limit, and returns the provider response. The app checks upcoming schedule conflicts before M02 and Gemini. Request contains minimal workout choices, derived M04 metrics and prefiltered exercise IDs. It excludes allergies, meal/food data, sleep preferences, DOB, name, notes and direct profile measurements. Response contains only the 28-day workout schema and allowlisted exercise IDs.

## M32-API02 — Gemini remaining-week replan

Transport: same backend, operation `fitness_training_replan`. Request adds the selected program window and effort/soreness scores; it contains no free-text note, food or sleep data. A schedule conflict is checked before check-in persistence, quota and AI. Member calls pass M02 quota checks. Guest is blocked from replan. Output is a workout-only preview for the remaining days; applying it requires a second user confirmation.

## Validation and transaction

1. Validate self-declared local adult eligibility and request identity.
2. Before quota/AI, derive the next seven days of workout intervals from selected weekdays, start time and duration. Ignore past/completed schedule entries and M32 future incomplete workouts that would be replaced.
3. Treat events without an end time as points; extend overnight events into the next day. M32 meal/sleep rows and other sources remain conflict candidates.
4. If requested time conflicts, compare the eight existing choices by distance, earlier first on ties. A proposal is valid only when free on every selected workout date. Ask for one-time consent before quota/AI; refusal or no available time leaves profile, program and schedule unchanged.
5. For Member, require the current authenticated user and M02 quota decision. For Guest, preflight the one-time initial-plan allowance before AI; consume it atomically with valid preview persistence.
6. Filter the static exercise catalog before constructing the bounded AI context. Food groups, allergens, recipes and sleep preferences are not part of this operation.
7. Parse only the workout-only response keys; validate day count/index, rest-day schedule, exercise IDs, selected equipment, movement exclusions and exercise bounds. New program days store empty meals and blank legacy sleep fields; older saved meal/sleep JSON remains readable.
8. Save a preview only after the entire response validates.
9. On confirmation, repeat overlap detection inside the SQLite transaction before archiving programs or changing schedule rows. Any conflict rolls the transaction back. If clear, delete only future incomplete M32 `routine` rows and insert workouts; preserve M32 meal/sleep, completed, past and unrelated rows. A new conflict gets a fresh availability check and consent request; the user confirms apply again.
10. Changing the selected time while a preview exists reapplies the same preview and does not call AI again. Request existing M05 snapshot synchronization after local commit. Current cloud schema is self-subject only; FamilyPlus dependent subjects remain outside the pilot.

## Error contract

| Condition | Behavior |
|---|---|
| AGE_NOT_ELIGIBLE / AGE_UNVERIFIED | Block before quota and AI; DOB remains local. |
| QUOTA_EXCEEDED | Do not call AI; preserve current program and schedule. |
| SCHEDULE_CONFLICT | Before AI, report requested time/conflict count, offer the nearest all-days-free time and ask consent; decline/no slot has no quota, AI or write effect. At apply, roll back and re-ask for consent after a fresh check. |
| INVALID_CATALOG_REFERENCE / INVALID_PROGRAM | Discard the whole result; do not persist or apply it. |
| AI/network failure | Preserve active program/schedule; retry is keyed by request ID locally. |
| GUEST_INITIAL_PLAN_USED | Do not call AI; preserve current state. |
| SCHEDULE_APPLY_FAILED | Local transaction rolls back; preview remains available for retry. |

The Edge Function has operation/rate-limit tests; it does not independently enforce M02 quota or validate catalog semantics. Sandbox review must confirm whether server-side quota enforcement is required before production release. M32 remains Draft/pilot, with Tech/Privacy, Clinical and QA approvals pending.
