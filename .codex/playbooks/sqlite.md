# Playbook — SQLite / DAO / Migration

## Mục tiêu

DB thay đổi phải đồng bộ đủ table/model/DAO/migration/onCreate và không phá dữ liệu cũ.

## Khi đổi schema

Bắt buộc kiểm tra:

- `database_version.dart`
- `database_service.dart` / onCreate
- `migrations/`
- `tables/`
- `models/`
- `daos/`
- datasource/repository gọi DAO.

## Quy tắc

- Không sửa migration cũ nếu đã phát hành; thêm migration mới.
- Tăng database version khi đổi schema.
- `onCreate` cho app cài mới phải tạo đủ bảng mới nhất.
- Model phải map đúng column name, nullable/default rõ ràng.
- DAO không swallow exception im lặng nếu dữ liệu quan trọng.

## Test nên có

- Insert/read/update/delete cơ bản.
- Migration không mất dữ liệu quan trọng.
- Query dùng cho dashboard/schedule trả đúng thứ tự/thời gian.
