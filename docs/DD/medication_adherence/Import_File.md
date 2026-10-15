# Import File — M22 / Lịch dùng thuốc

## 1. Dependency rules

Keep `Presentation → Controller/Provider → Repository → Datasource/DAO →
SQLite`. Onboarding/settings views must not import DAO, SQLite models, or
database APIs. M22 submits schedule intent to M09; it does not own a second OS
notification bootstrap.

## 2. Source map

| Source area | Planned responsibility | Allowed dependencies |
|---|---|---|
| `lib/app_versions/v1/features/medication_reminders/domain/` | Entity and repository contract | Dart only |
| `lib/app_versions/v1/features/medication_reminders/data/` | SQLite DAO/repository for local-only table | Domain, sqflite DAO patterns |
| `lib/core/storage/localdb/tables/medication_reminders_table.dart`, `migrations/migration_v34.dart` | Table and idempotent create/ensure | Core database only |
| `lib/app_versions/v1/features/onboarding/` | Draft list, validation, onboarding transaction and review UI | M22 repository contract; no DAO imports in presentation |
| `lib/app_versions/v1/services/notifications/` | Daily recurrence, deterministic IDs, safe payload and M09 navigation | Existing scheduler abstraction and local repository contract |
| `lib/app_versions/v1/features/settings/` | Reminder list/edit/pause/delete section | Provider/repository and M09 coordinator |
| `lib/app_versions/v2/features/cloud_sync/` | Re-key local-only rows only on confirmed `mergeNow` | Local table contract; do not add table to snapshot/outbox |
| `test/` | Focused migration, repository, onboarding, scheduler, settings and sync acceptance | Existing fakes/in-memory SQLite patterns |

## 3. External dependencies

No new package, API, Supabase SQL, RLS, cloud table, or quota contract. Reuse
`flutter_local_notifications`, `timezone`, `sqflite`, and existing app router.

