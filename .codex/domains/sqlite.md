# Domain - SQLite / DAO / Migration

## Source

- `lib/core/storage/localdb/database_version.dart`
- `lib/core/storage/localdb/database_service.dart`
- `lib/core/storage/localdb/migrations/`
- `lib/core/storage/localdb/tables/`
- `lib/core/storage/localdb/models/`
- `lib/core/storage/localdb/daos/`
- Tests: `test/core/storage/localdb/`.

## Rules

- Current version: `DatabaseVersion.currentVersion = 12`.
- Schema changes require version bump, migration, table/model/DAO updates, onCreate update, datasource/repository updates, and tests.
- Do not edit released migrations unless explicitly required and safe.
- UI never calls DAO or SQLite directly.
- Date/time queries need explicit format/timezone decisions.

## Search

```powershell
rg "CREATE TABLE|ALTER TABLE|databaseVersion|currentVersion|onCreate|migration" lib/core/storage/localdb test/core/storage/localdb
rg "SELECT|INSERT|UPDATE|DELETE|rawQuery|transaction" lib/core/storage/localdb/daos lib/app_versions test
```
