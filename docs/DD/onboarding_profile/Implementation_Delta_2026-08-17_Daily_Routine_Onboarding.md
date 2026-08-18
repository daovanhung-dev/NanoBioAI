# Implementation Delta — Daily Routine onboarding — 2026-08-17

## Scope

This delta brings M01 documentation in line with the current v1 onboarding runtime that includes the **Daily Routine Preferences / Nhịp sống mỗi ngày** step.

## Runtime flow

```text
Welcome
-> Personal Information
-> Health Goals
-> Health Conditions
-> Lifestyle Habits
-> Extras
-> Daily Routine Preferences
-> Consent & Disclaimer
-> Review & Submit
```

Daily Routine must validate before the user can continue. On final submit, onboarding first persists the profile/local subject and durable guest identity, then persists routine preferences for that exact subject before generating the initial plan.

## Ownership / subject rule

Daily Routine current-subject access must use the canonical `LocalSubjectResolver`:

1. authenticated actor / trusted subject context when available;
2. otherwise the durable pending guest id;
3. if neither identifies a subject, fail closed.

**Forbidden:** selecting identity by storage recency (`users.created_at`, last row, latest row, or equivalent heuristics).

The datasource only accepts explicit `userId` for `loadForUser` / `saveForUser`; subject resolution belongs above the datasource layer.

## Persistence

- Storage: `survey_answers`.
- Stable question code: `daily_routine_preferences_v1` through `DailyRoutinePreferences.questionCode`.
- Stable row ownership is the resolved subject id.
- Save triggers the existing local user-data sync dispatcher.

## Error / empty semantics

```text
load success + record exists -> edit persisted values
load success + record absent -> defaults are a valid initial draft
load failure                -> error + Retry only; Save is unavailable
```

A transient read/decode failure must never be treated as an empty record and must never allow defaults to overwrite a previously saved routine.

## Schedule impact

Routine preferences are inputs for newly generated schedule timing. Editing the routine does not retroactively mutate already-created schedule items unless a separate regeneration flow is explicitly invoked.

## Acceptance cases

- Guest A remains the owner even when another local user B has a newer `created_at`.
- Missing authenticated actor + missing durable guest id fails closed.
- Authenticated subject never reads/writes another local user's routine by recency.
- Load error shows Retry and cannot Save.
- Genuine empty record may start from defaults and Save explicitly.
