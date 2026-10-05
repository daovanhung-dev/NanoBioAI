# Import/File Map — M32 / Chế độ luyện tập

## Dependency rules

Follow Presentation → Provider/Controller → Application service → Repository → Datasource/API. UI does not call SQLite, Supabase, Gemini or the quota gateway directly. Runtime code was added under the PO-directed pilot exception recorded in `Overall.md`; reviewer sign-offs remain pending.

## Current source map

| Area | Source | Responsibility | Evidence / boundary |
|---|---|---|---|
| Feature entry | `lib/app_versions/v1/features/features_hub/presentation/pages/features_hub_page.dart`, `lib/app_versions/v1/router/` | FeatureHub tile, route, Guest allowance | Reachable from v1 FeatureHub; Android/iOS are the pilot target. |
| UI and state | `lib/app_versions/v1/features/fitness_training/presentation/` | Profile review, eligibility, intake, catalog choices, preview/apply, current week, check-in and video fallback | Controller-backed page; includes wellness/pilot disclosure and accessibility labels. |
| Provider/controller | `lib/app_versions/v1/features/fitness_training/presentation/providers/`, `application/fitness_training_controller.dart` | Load profile/catalog/programs; local M04-derived metrics; build intake and state | Does not serialize DOB, name or profile notes into Gemini intake. |
| Domain | `lib/app_versions/v1/features/fitness_training/domain/` | Program, catalog, age gate, repository contracts and strict Gemini response validation | Fail-closed venue/equipment/allergen/movement validation and bounded workout prescriptions. |
| Application | `lib/app_versions/v1/features/fitness_training/application/fitness_training_service.dart` | M02 check/commit, Guest quota preflight, generate/replan, request dedupe, preview, apply | Existing Gemini backend client; M02 rejection happens before AI. |
| Data | `lib/app_versions/v1/features/fitness_training/data/` | Draft static asset loading, local profile/program persistence, schedule transaction | SQLite owns Guest/local data and self-owned local program rows; FamilyPlus subject flow is not implemented. |
| Static catalog | `assets/data/fitness_training/` | 24 exercise, 10 equipment, 35 recipe, 47 candidate ingredient rows and nine original illustration atlases | FDC IDs/provenance retained. Records remain pilot candidates pending content/clinical review. |
| Database | `lib/core/storage/localdb/migrations/migration_v25.dart`, `tables/fitness_training_programs_table.dart` | 28-day program aggregate and status index | M32 programs sync through the existing user snapshot contract. |
| Cloud sync contract | `lib/app_versions/v2/features/cloud_sync/data/datasources/`, `docs/supabase/01_build_system.sql` | Snapshot serialization and self-owner RLS/read policy | Source only; SQL has not been applied in sandbox or production. Client direct writes are revoked in source SQL. |
| Edge Function | `supabase/functions/nabi-ai-generate/` | Allow only named M32 generate/replan operations through existing server-side Gemini provider | `GEMINI_API_KEY` remains server-only. Handler checks operation/rate limits and bounds requests; catalog semantics are validated by the app before persistence. |
| YouTube player | `youtube_player_iframe` and M32 presentation | Official IFrame wrapper for individually approved IDs | No current candidate is approved for embedding; fallback is the app illustration, instructions and open/search on YouTube. |

## Schedule and persistence behavior

- `FitnessTrainingLocalDatasource.applyWeek` updates the program and schedule in a SQLite transaction.
- It removes only incomplete `fitness_training` schedule items whose scheduled time is still in the future; completed items, past items, earlier same-day items, health tasks and other sources remain.
- It writes only the selected seven-day program window, then requests the existing M05 sync dispatcher.
- Member program rows are self-owned in the current Supabase source contract. FamilyPlus dependent subjects are intentionally not represented by this pilot schema pending the product/security decision.
- Guest one-time entitlement is read before the AI call and consumed in the same local transaction that stores a valid preview.

## Verification state

See `docs/worklog/2026-10-05/003-worklog-m32-runtime.md` for exact commands and results. Local analyzer, focused Flutter tests and Edge handler tests passed. Android debug build, if successful in the current run, proves packaging only. There is no live Gemini call, quota sandbox exercise, Supabase migration, real-device acceptance, or iOS build evidence yet.

## External dependencies

| Dependency | Version/status | Use | License / boundary |
|---|---|---|---|
| `youtube_player_iframe` | Resolved version in `pubspec.lock` | Official YouTube IFrame inside Android/iOS app | Package license and upstream player terms apply; no video/thumbnail download or rehosting. |
| USDA FoodData Central | Static source import | Ingredient nutrition values | Retain FDC ID and source metadata; no runtime API key/request. |
| Gemini | Existing `nabi-ai-generate` Edge Function | Structured program and remaining-week suggestion | Secret remains server-side; client does not contain Gemini key. |

## Configuration and secrets

Only the existing server-side `GEMINI_API_KEY` is required. No USDA key, YouTube API key or Gemini key belongs in Flutter, local configuration or catalog assets. Do not log raw profile, prompt or Gemini response.
