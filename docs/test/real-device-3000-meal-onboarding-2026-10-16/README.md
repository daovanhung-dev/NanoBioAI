# Real-device catalog seed and onboarding status — 2026-10-16

## Scope

Verify the updated Flutter app and the 3,000-meal SQLite seed on the connected
Xiaomi 220333QPG. This record covers device startup and migration only; it does
not claim that onboarding finished or that AI generated a schedule.

## Device and app

- Device: Xiaomi 220333QPG, Android 11 (API 30), connected by USB.
- Package: `com.nanobioai.app`, debuggable build.
- A `flutter run` session was already active for this workspace. Attached with
  `flutter attach --device-id 12b304f9 --app-id com.nanobioai.app --no-dds`;
  the tool synchronized current files. Sent hot restart (`R`); restart completed
  in 6,648 ms.
- The local build configuration resolves the plan AI route through the app's
  Supabase Edge Function `nabi-ai-generate`, which calls Gemini. No request was
  made during this verification.

## Database evidence

Before restart, the on-device database reported SQLite version 35, 163 meal
rows, 40 exercise rows, one profile, two goals, one condition, one lifestyle
row, and 12 survey answers. The user state was `in_progress`; one prior
`initial_guest` request had status `failed` and had committed zero meals and
zero exercises. Its staging record used the old v10 prompt. No health values,
names, IDs, or raw prompt were printed.

After restart, the same on-device database reported:

- SQLite version 36.
- 3,163 meal rows: 3,000 candidate and 163 legacy.
- 40 exercise rows.
- Existing profile-related table counts unchanged.
- Existing onboarding status and failed request preserved; no new AI request
  or schedule rows were created.

## Result and remaining acceptance

Device startup, current-code synchronization, and catalog migration/seed are
verified. Onboarding remains `in_progress`, and the previous guest generation
did not produce a schedule. The computer-use surface reports no native apps and
does not expose Android windows, so this session cannot navigate the remaining
onboarding controls or press the in-app generate action. Consequently there is
no live Gemini response or quota result yet. The connected device is mirrored
through `scrcpy` so the app can be continued once an interactable UI surface is
available.

Do not report this as end-to-end schedule acceptance. The next evidence must
show the remaining onboarding step completed, a new backend invocation through
the normal app flow, and the committed 35 meals/14 activities in the on-device
database and UI.
