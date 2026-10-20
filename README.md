# NanoBioAI / Nabi

NanoBioAI là ứng dụng Flutter chăm sóc sức khỏe cá nhân theo hướng
**local-first**, với Nabi làm trợ lý đồng hành. Tài liệu này mô tả trạng thái
source tại baseline `25018e8` (2026-08-24); kết quả runtime/device hoặc Supabase
sandbox không được suy ra từ việc source tồn tại.

## Source of truth

Khi tài liệu mâu thuẫn, dùng thứ tự sau:

1. Code reachable từ `lib/main.dart`.
2. SQLite runtime và bộ SQL Supabase có thể rebuild.
3. `pubspec.yaml`, `pubspec.lock` và cấu hình Android/iOS.
4. Test/validator thực thi được.
5. Tài liệu hiện hành; tài liệu lịch sử chỉ là bằng chứng tại thời điểm tạo.

Entry point cho toàn bộ tài liệu là `docs/README.md`. Báo cáo đối chiếu và
inventory nằm trong `docs/audit/`.

Các nhãn trạng thái dùng trong tài liệu:

- `Implemented`: có đường gọi reachable và xử lý thật trong source.
- `Partial`: có đường chạy thật nhưng capability chưa bao phủ toàn bộ phạm vi.
- `Placeholder`: route/UI chỉ giới thiệu hoặc báo đang phát triển.
- `Source-only`: có source/schema nhưng không có consumer reachable từ
  `lib/main.dart`.
- `Absent`: không có implementation trong source hiện tại.

## Runtime hiện tại

```text
lib/main.dart
  -> nạp cấu hình tùy chọn
  -> khởi tạo Supabase nếu đủ URL + anon key
  -> ProviderScope
  -> BioAIApp
       -> User surface: một GoRouter gộp V1 + V2 + V3 routes
       -> Admin surface: adminRouter khi backend xác nhận quyền Admin
  -> cloud sync + meal-catalog refresh khi Supabase sẵn sàng
  -> local notification startup
```

Chỉ có một entrypoint ứng dụng: `lib/main.dart`. Các file cũ như
`lib/main_v2.dart` và `lib/main_admin.dart` không tồn tại.

Supabase là tùy chọn đối với bootstrap và guest mode. Auth, cloud sync,
membership, quota, payment, FamilyPlus, Sale và Admin cần Supabase hợp lệ;
không có cấu hình thì các capability đó không được xem là hoạt động.

## Trạng thái capability

| Khu vực | Trạng thái theo source |
| --- | --- |
| V1 guest/basic | `Implemented` cho onboarding 9 bước, hồ sơ/local data, dashboard, lịch, meal plan, tracking cơ bản và notification. |
| V1 AI plan | `Implemented`: tạo gợi ý bằng model trên thiết bị; Supabase tiếp tục xử lý đăng nhập, dữ liệu và quota hiện có. |
| V1 AI chat/voice | `Partial`: route cần đăng nhập; nội dung AI chạy trên thiết bị, các giới hạn/quyền hiện có vẫn cần Supabase. |
| V1 planned UI | `Placeholder`: sleep, stress, community; personal goals chỉ là preview không lưu. |
| V2 authenticated | `Implemented/Partial`: auth, merge/cloud sync, entitlement, quota, health score, payment request và Wellness Rewards có đường runtime; cần backend để kiểm chứng end-to-end. |
| M20-M29 | `Placeholder`: catalog và access/upgrade/coming-soon UI; chưa có business storage/flow cho từng module. |
| V3 | `Partial`: advanced tracking và FamilyPlus có route, provider, repository và access gate; V3 home vẫn là catalog “Sắp có”. |
| V3 marker modules | `Source-only`: premium AI, goal roadmap, advanced health tracking, family onboarding/members/schedule chỉ khai báo `planned`. |
| M30 Nabi notifications | `Source-only`: SQLite v20 tables, models, engine và repositories có source nhưng chưa có consumer reachable từ app bootstrap/UI. |
| Sale/referral | `Partial`: Sale UI/RPC cho trạng thái, khách trực tiếp, điểm và conversion; phê duyệt/payment success vẫn là backend/Admin. |
| Admin | `Partial`: surface và các section/RPC có source, được mở sau trusted role resolution; cần Supabase policy/RPC để chạy thật. |

Chi tiết và evidence path xem `SYSTEM_FEATURES_DOCUMENTATION.md`.

## AI trên thiết bị và cấu hình

Ứng dụng native yêu cầu chọn và tải một model văn bản trước khi vào phần dành
cho người dùng. Model chạy bằng `llamadart` trên thiết bị; Food Scan tải riêng
model nhận ảnh trong lần quét đầu tiên. NanoBioAI không gửi prompt, câu trả lời
hoặc ảnh tới dịch vụ AI từ xa. Bản web giữ các luồng không dùng AI và thông báo
khi người dùng mở tính năng cần runtime local.

Supabase vẫn được cấu hình bằng `SUPABASE_URL` và `SUPABASE_ANON_KEY` để phục vụ
đăng nhập, dữ liệu, đồng bộ và quota hiện có. Không cần cấu hình API key AI
trong app. Không commit service-role key, session token hoặc `.env` thật.

## Stack và identity

- Package Dart: `nano_app`, version `1.0.0+1`, SDK constraint `^3.9.2`.
- Riverpod `^3.3.1`, GoRouter `^17.2.3`, sqflite `^2.4.2`.
- Supabase Flutter `^2.12.4`.
- Local notifications `19.5.0`; SQLite schema runtime `20`.
- Android namespace/application ID: `com.nanobioai.app`; label: `NanoBio`.
- iOS bundle ID: `com.example.nanoApp`; display name: `NaBi`.

Android và iOS hiện chưa cùng bundle/application identifier; tài liệu không
được tự quy chúng về một ID.

## Cấu trúc nguồn

```text
lib/
├── main.dart
├── app/                    # root surface selection
├── app_versions/
│   ├── v1/                 # guest/basic + shared user experience
│   ├── v2/                 # authenticated capabilities + merged user router
│   ├── v3/                 # paid-gated partial flows + planned markers
│   └── admin/              # trusted Admin surface
├── core/                   # config, access, SQLite, theme
├── services/               # Supabase and device/shared services
├── sale_referral/          # independent Sale role axis
└── shared/

test/
integration_test/
docs/
.codex/
```

## Chạy ứng dụng

Cài dependency:

```powershell
flutter pub get
```

Kiểm tra cấu hình mà không chạy Flutter:

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_v2.ps1 -ValidateOnly
```

Chạy unified app:

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_v2.ps1
```

Plain `flutter run -t lib/main.dart` có thể mở guest mode. Dùng script trên cho
authenticated/AI testing vì script chuẩn bị runtime defines theo contract dự
án.

## Validation

Ưu tiên kiểm tra đúng phạm vi:

```powershell
dart format --set-exit-if-changed <paths>
flutter analyze <paths>
flutter test <paths>
```

Docs/source-truth:

```powershell
python tools/validate_docs_source_truth.py
powershell -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1
git diff --check
```

Runtime quick/full check:

```powershell
powershell -ExecutionPolicy Bypass -File .codex/tool/codex_quick_check.ps1
powershell -ExecutionPolicy Bypass -File .codex/tool/codex_check.ps1 -BuildApk
```

Nếu Flutter/device/Supabase sandbox chưa chạy, kết quả phải ghi `UNVERIFIED`,
không được ghi `PASS` dựa trên static inspection.

## Agent context

Coding agent bắt đầu từ `AGENTS.md`, rồi làm theo router trong `.codex/`.
Không dùng worklog hoặc delivery manifest lịch sử để thay cho source hiện tại.
