# Architecture

## Loại kiến trúc
**Feature-first + Clean Architecture** — mỗi feature tự đóng gói theo 3 layer.

## Stack kỹ thuật
- **Framework**: Flutter (Dart SDK ^3.9.2)
- **State Management**: Riverpod 3 (`flutter_riverpod ^3.3.1`)
- **Navigation**: GoRouter (`go_router ^17.2.3`)
- **Local DB**: SQLite via `sqflite ^2.4.2`
- **Remote Auth**: Supabase (`supabase_flutter ^2.12.4`)
- **AI**: Google Gemini (`google_generative_ai ^0.4.7`, model: `gemini-2.5-flash`)
- **HTTP**: Dio (dùng trong AI service)
- **Preferences**: `shared_preferences`
- **Env**: `flutter_dotenv`

## Layers trong mỗi Feature

```
presentation/
  ├── pages/        ← màn hình UI
  ├── controllers/  ← StateNotifier / AsyncNotifier (Riverpod)
  └── widgets/      ← widget riêng của feature

domain/
  ├── entities/     ← plain Dart object, không phụ thuộc framework
  └── repositories/ ← abstract + impl (chứa impl luôn tại đây)

data/
  ├── datasources/  ← tương tác SQLite / Supabase
  └── models/       ← extends entity, có fromJson/fromMap

providers/           ← Riverpod Provider wiring datasource → repo → controller
```

## Luồng dữ liệu chính

```
UI (Page)
  ↓ watch/read
Provider (Riverpod)
  ↓
Controller (Notifier / AsyncNotifier)
  ↓
Repository (abstract + impl)
  ↓
Datasource (SQLite / Supabase)
  ↓
Local: DatabaseService (sqflite)  |  Remote: Supabase.instance.client
```

## Cấu trúc thư mục gốc

```
lib/
├── main.dart           ← entry point: load .env → init Supabase → ProviderScope
├── app/app.dart        ← BioAIApp: MaterialApp.router + AppTheme + appRouter
├── core/               ← constants, network, router, storage, theme, utils
├── features/           ← mỗi feature = 1 thư mục độc lập
├── services/           ← AI service, Supabase service
└── shared/             ← widgets dùng chung
```

## Quan hệ layer / module

- `features/*` → depends on `core/`, `services/`
- `features/*` KHÔNG import lẫn nhau trực tiếp (ngoại lệ: `onboarding_controller` gọi `dashboardControllerProvider` sau khi save để trigger `genMealByWeeksToDB`)
- `services/ai` → được inject qua Riverpod Provider, không phụ thuộc feature cụ thể
- `core/storage/localdb` → singleton `DatabaseService`, dùng toàn hệ thống

## Quyết định kiến trúc nổi bật

| Quyết định | Lý do |
|---|---|
| SQLite làm primary storage | Offline-first, không cần internet để dùng app |
| Supabase chỉ cho auth | Giảm dependency cloud, dữ liệu nhạy cảm giữ local |
| Gemini AI cho meal plan | Tạo kế hoạch cá nhân hóa dựa trên health profile |
| Riverpod Notifier (gen3) | Type-safe, không dùng `StateProvider` legacy |
| Repository pattern | Dễ mock test, tách biệt data source |
