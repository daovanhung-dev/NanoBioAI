# Playbook - SQLite / DAO / Migration

## Muc tieu

Moi thay doi DB phai dong bo schema, model, DAO, migration, onCreate va khong pha du lieu cu.

## Doc truoc

- `lib/core/storage/localdb/database_version.dart`
- `lib/core/storage/localdb/database_service.dart`
- `lib/core/storage/localdb/migrations/`
- `lib/core/storage/localdb/tables/`
- `lib/core/storage/localdb/models/`
- `lib/core/storage/localdb/daos/`
- Tests: `test/core/storage/localdb/`

## Snapshot

- Version hien tai: `DatabaseVersion.currentVersion = 8`.
- Doi schema thi tang version va them migration moi.

## Quy tac schema

- Khong sua migration cu neu da phat hanh; them migration moi.
- `onCreate` phai tao schema moi nhat cho app cai moi.
- Model map dung column name, nullable/default ro rang.
- DAO khong swallow exception im lang voi data quan trong.
- Query theo ngay/gio phai ro format/timezone.
- Repository/datasource goi DAO theo pattern hien co, UI khong goi DAO.

## Checklist doi schema

- [ ] `database_version.dart`
- [ ] `tables/*.dart`
- [ ] `models/*.dart`
- [ ] `daos/*.dart`
- [ ] `migrations/migration_vX.dart`
- [ ] `database_service.dart` / `onCreate`
- [ ] datasource/repository lien quan
- [ ] CRUD/migration tests

## Tim nhanh

```bash
rg "CREATE TABLE|ALTER TABLE|databaseVersion|currentVersion|onCreate|migration" lib/core/storage/localdb test/core/storage/localdb
rg "SELECT|INSERT|UPDATE|DELETE|rawQuery|transaction" lib/core/storage/localdb/daos lib/features test
```

## Test nen chay

- `flutter test test/core/storage/localdb`
- Test feature lien quan neu DAO duoc goi qua datasource.
