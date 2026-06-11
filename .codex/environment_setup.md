# Environment Setup

## Prerequisites
- Flutter SDK (Dart ^3.9.2)
- Android SDK (cho Android target)
- Xcode (cho iOS target)
- `.env` file ở root (xem bên dưới)

## Biến môi trường (`.env`)

```env
SUPABASE_URL=https://<project>.supabase.co
SUPABASE_ANON_KEY=<anon_key>
GEMINI_API_KEY=<google_ai_api_key>
GEMINI_BASE_URL=https://generativelanguage.googleapis.com/v1beta
GEMINI_MODEL=gemini-2.5-flash
```

File `.env` phải nằm ở root dự án và được khai báo trong `pubspec.yaml` assets:
```yaml
assets:
  - .env
  - assets/
```

⚠️ File `.env` KHÔNG có trong `.gitignore` — đang được commit vào repo. Cần cẩn thận với credentials khi push.

## Lệnh

```bash
# Install dependencies
flutter pub get

# Chạy app (debug)
flutter run

# Build Android APK
flutter build apk

# Build iOS
flutter build ios

# Phân tích code
flutter analyze
```

## Khởi tạo database
Database SQLite (`bioai.db`) được tạo tự động khi app chạy lần đầu qua `DatabaseService._initDatabase()`. Không cần seed hay migration thủ công.

## App Icons
```bash
flutter pub run flutter_launcher_icons
```
Cần file `assets/icons/logo.png` tồn tại.

## Không có Docker, CI/CD
Hiện tại dự án chưa có cấu hình Docker, CI/CD, hoặc deployment pipeline.

## Local SQLite location
- Android: `/data/data/com.example.nano_app/databases/bioai.db`
- iOS: `Library/Application Support/bioai.db`
