# Dependencies

## Core dependencies

| Package | Version | Vai trò |
|---|---|---|
| `flutter_riverpod` | ^3.3.1 | State management — **kiến trúc cốt lõi** |
| `go_router` | ^17.2.3 | Navigation, route guards |
| `supabase_flutter` | ^2.12.4 | Authentication (Supabase cloud) |
| `sqflite` | ^2.4.2 | Local SQLite database |
| `google_generative_ai` | ^0.4.7 | Gemini AI SDK |
| `dio` | ^5.9.2 | HTTP client (dùng trong AIService) |
| `flutter_dotenv` | ^6.0.1 | Load `.env` vars |
| `shared_preferences` | ^2.5.3 | Lưu flag đơn giản (onboarding) |
| `path` + `path_provider` | ^1.9.1 / ^2.1.5 | SQLite file path |
| `connectivity_plus` | ^7.1.1 | Kiểm tra kết nối mạng [INFERRED - không thấy usage hiện tại] |

## Dev dependencies

| Package | Vai trò |
|---|---|
| `flutter_lints` | Lint rules |
| `flutter_launcher_icons` | Generate app icons từ `assets/icons/logo.png` |
| `rename` | Rename app package name |

## Ảnh hưởng kiến trúc

- `flutter_riverpod` — toàn bộ DI và state flow đi qua Riverpod Providers. Thay đổi cách provide service sẽ ảnh hưởng mọi nơi.
- `sqflite` — **offline-first**. Mọi dữ liệu người dùng đọc/ghi local, không sync lên cloud.
- `supabase_flutter` — chỉ dùng cho auth. Nếu muốn thay auth provider phải sửa `AuthRemoteDatasource` và `RouteGuards`.
- `go_router` — điều hướng declarative. `appRouter` là singleton, guards inject trực tiếp vào route definition.
- `google_generative_ai` — AI generation dùng SDK chính thức của Google, không raw HTTP. Timeout và model config trong `AIService` constructor.

## Notes

- `connectivity_plus` được import nhưng chưa thấy integration trong code hiện tại
- `flutter_riverpod` import cả `legacy.dart` (`StateNotifierProvider` trong auth) — auth chưa migrate sang gen3 Notifier
