# NanoBioAI / Nabi

NanoBioAI là ứng dụng Flutter chăm sóc sức khỏe cá nhân theo hướng **local-first**, với Nabi làm trợ lý đồng hành. Ứng dụng kết hợp hồ sơ sức khỏe, lịch sinh hoạt, thực đơn, theo dõi hằng ngày, AI, thông báo và các lớp quyền tài khoản trên một runtime thống nhất.

## Runtime hiện tại

```text
lib/main.dart
  -> nạp cấu hình tùy chọn
  -> khởi tạo Supabase nếu có cấu hình hợp lệ
  -> ProviderScope
  -> BioAIApp
       -> User surface (V1 + V2 + V3 routes)
       -> Admin surface khi session được backend xác nhận
  -> cloud sync khi backend sẵn sàng
  -> local notifications
```

### Các lớp sản phẩm

- **V1 guest/basic**: onboarding, hồ sơ local, lịch cá nhân đầu tiên, meal plan, daily health tracking, lifestyle schedule và notification.
- **V2 authenticated/free**: Supabase Auth, guest merge/cloud sync, quota, health score, membership/payment và Wellness Rewards.
- **V3 Plus/FamilyPlus**: advanced tracking, FamilyPlus và các module paid được triển khai theo contract hiện hành.
- **Admin**: surface quản trị dùng access backend riêng.
- **Sale/referral**: trục vai trò độc lập, không phải membership tier.

## Kiến trúc

Dependency flow bắt buộc:

```text
Presentation
  -> Provider / Controller
  -> Repository interface
  -> Repository implementation
  -> Datasource
  -> DAO / Supabase RPC / external service
```

Presentation không truy cập DAO/SQLite/API trực tiếp. Dữ liệu user-owned phải luôn được scope bằng active `user_id` / subject đã resolve.

## Stack chính

- Flutter / Dart
- Riverpod
- GoRouter
- SQLite (`sqflite`) — schema runtime hiện tại: **v20**
- Supabase Auth + cloud sync
- Gemini-backed AI services với local fallback theo từng flow
- `flutter_local_notifications`

## Local-first và Guest

Thiếu cấu hình Supabase không ngăn app khởi động ở guest mode. Guest onboarding dùng catalog local đã seed/cache để tạo lịch đầu tiên; khi Supabase khả dụng, catalog remote được dùng để refresh cache nhưng lỗi mạng/remote rỗng không được phép xóa catalog local hợp lệ.

Identity local không được suy ra bằng “user mới nhất”. Guest dùng durable local user ID; authenticated flow resolve actor ở provider boundary, và `SubjectAccessContext` được dùng tại các flow có selected subject/FamilyPlus context.

## Cấu trúc nguồn

```text
lib/
├── main.dart
├── app/
├── app_versions/
│   ├── v1/
│   ├── v2/
│   ├── v3/
│   └── admin/
├── core/
│   ├── access/
│   ├── config/
│   ├── storage/localdb/
│   └── theme/
├── services/
├── sale_referral/
└── shared/

test/
integration_test/
docs/
.codex/
```

## Chạy ứng dụng

Cài dependencies:

```powershell
flutter pub get
```

Kiểm tra cấu hình runtime mà không khởi động Flutter:

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_v2.ps1 -ValidateOnly
```

Chạy unified app:

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_v2.ps1
```

Không cần Supabase để mở guest flow. Các chức năng authenticated/cloud cần cấu hình hợp lệ. Không commit `.env`, API key hoặc session token.

## Validation

Ưu tiên validation theo phạm vi file đã chạm:

```powershell
dart format <paths>
dart format --set-exit-if-changed <paths>
flutter analyze <paths>
flutter test <paths>
```

Runtime quick check:

```powershell
powershell -ExecutionPolicy Bypass -File .codex/tool/codex_quick_check.ps1
```

Full/native check khi scope yêu cầu:

```powershell
powershell -ExecutionPolicy Bypass -File .codex/tool/codex_check.ps1 -BuildApk
```

Context/docs integrity:

```powershell
powershell -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1
git diff --check
```

## Agent context

Coding agent phải bắt đầu từ:

1. `AGENTS.md`
2. `.codex/AGENTS.md`
3. `.codex/PROJECT_MAP.md`
4. `.codex/history/LEARNED_SKILLS.md`
5. workflow + task-skill + domain đúng task

Runtime source và tests là source-of-truth khi README/context cũ mâu thuẫn với code.
