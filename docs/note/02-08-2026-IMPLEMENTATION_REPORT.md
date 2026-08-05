# Báo cáo triển khai task ngày 02-08-2026

## Kết luận

Task trong `docs/note/02-08-2026.md` đã được triển khai ở cấp source code, schema, test source và tài liệu vận hành. Phiên bản SQLite mới là **V17**.

Bản triển khai giữ các guardrail chính của NanoBio:

- không phá luồng guest/auth/cloud sync/quota/notification;
- không cho UI gọi DAO/API trực tiếp ở phần mới;
- không đưa dữ liệu y tế suy diễn vào catalog;
- AI chỉ chọn `meal_code` từ candidate pool đã lọc;
- đổi món dùng cùng policy với tạo thực đơn;
- voice dùng chung AI Chat repository, quota và lịch sử;
- file bí mật không được đưa vào gói bàn giao.
- toàn bộ đường dẫn asset khai báo trong `pubspec.yaml` khớp đúng casing và tồn tại trong project đóng gói.

## Hạng mục hoàn thành

| Hạng mục | Trạng thái | Kết quả chính |
|---|---|---|
| Chọn cỡ chữ trước onboarding | Hoàn thành source | 4 nấc, app-wide, có Settings, tôn trọng scale hệ thống |
| Hồ sơ dinh dưỡng | Hoàn thành source | Form 5 chặng, 8 bảng SQLite/Supabase, transaction save |
| Chi tiết công thức | Hoàn thành source | Bottom sheet nguyên liệu, chế biến, lợi ích, provenance, disclaimer |
| Đổi món | Hoàn thành source | Cùng candidate policy, transaction meal/timeline, refresh reminder |
| AI chọn theo mã catalog | Hoàn thành source | Code-only normalize, filtered candidate pool, snapshot provenance |
| 163 công thức | Hoàn thành import | 163 món, 64 chủ đề, 11 chương, không suy diễn metadata thiếu |
| Supabase cache | Hoàn thành source/SQL | Active catalog read, client write denied, last-good local cache |
| Giao tiếp giọng nói | Hoàn thành source | STT/TTS tiếng Việt, cùng quota AI Chat, lifecycle-safe |
| SQLite migration | Hoàn thành source | V16 -> V17 additive/idempotent |
| Test source | Hoàn thành | 8 file test mục tiêu |

## Quy tắc catalog an toàn

Dữ liệu nguồn chỉ có tên món, nguyên liệu, cách làm, lợi ích và ngữ cảnh chủ đề. Tài liệu không cung cấp đủ calories, macro, khẩu phần, allergen tags và chống chỉ định có cấu trúc. Vì vậy:

- toàn bộ 163 công thức được nhập với provenance đầy đủ;
- `metadata_status = source_imported`;
- `constraint_metadata_status = awaiting_professional_review`;
- `nutrition_status = missing_source_data`;
- `is_plan_eligible = false`.

App chỉ cho AI/đổi món dùng record có metadata và constraint đã `approved` đồng thời `is_plan_eligible=true`. Các món built-in đã duyệt trước đây vẫn hoạt động.

## Thay đổi dữ liệu

### SQLite V17

Thêm tám bảng:

1. `nutrition_profiles`
2. `health_symptoms`
3. `medication_records`
4. `food_restrictions`
5. `lab_results`
6. `nutrition_goals`
7. `meal_schedule_preferences`
8. `nutrition_preference_rules`

Mở rộng:

- `meal_catalog`: ingredients, steps, benefits, serving/nutrition, allergen/condition tags, metadata status, eligibility, source/version.
- `meal_plans`: catalog snapshot, ingredients/steps/benefits, serving/nutrition status, constraint tags, source/version, replacement count.

Các bảng hồ sơ mới được đưa vào sync outbox và cloud snapshot mapping.

### Supabase

- `docs/supabase/21-nutrition-profile-meal-catalog-v17.sql`
- `docs/supabase/22-meal-catalog-source-seed.sql`
- `docs/supabase/config.sql` đã nhận cùng contract để rebuild.

Catalog active có read policy cho anon/auth; direct client writes bị thu hồi. Hồ sơ dinh dưỡng đọc theo owner và ghi qua trusted sync RPC.

## Luồng runtime sau thay đổi

```text
Mở onboarding
-> chưa chọn cỡ chữ: hiển thị 4 nấc
-> lưu preset
-> chạy onboarding 9 bước hiện hữu

Tạo thực đơn
-> tải hồ sơ + catalog local last-good
-> lọc approved/eligible + meal type + restriction/condition
-> gửi candidate codes cho AI
-> AI trả meal_code
-> app hydrate snapshot từ catalog
-> lưu meal plan + timeline + notification

Đổi món
-> xác nhận
-> dùng cùng candidate selector
-> loại món hiện tại
-> update meal plan + linked timeline trong transaction
-> refresh state + notification

Voice AI
-> auth guard
-> chào bằng TTS
-> STT vi_VN
-> AIChatRepository.sendMessage()
-> cùng quota/history/persistence
-> TTS vi-VN
```

## Validation

Đã PASS ở mức tĩnh:

- 163 công thức, 64 chủ đề, source fidelity;
- Python syntax;
- Dart delimiter/import resolution trên file thay đổi;
- XML/plist/YAML/JSON parser;
- SQLite/Supabase/outbox/seed contract scan;
- archive không chứa file cấu hình nhạy cảm.

Chưa thể chứng nhận:

- `dart format`;
- `flutter analyze`;
- `flutter test`;
- APK build;
- Android/iOS device test;
- Supabase sandbox/RLS multi-user.

Nguyên nhân: môi trường thực thi không có Flutter/Dart/Android toolchain, thiết bị thật hoặc Supabase sandbox an toàn. Không có kết quả runtime nào được suy diễn.

## Checklist bắt buộc trước release

1. `flutter pub get`.
2. `dart format` các file Dart thay đổi.
3. `flutter analyze` source/test liên quan.
4. Chạy 8 test mục tiêu đã thêm.
5. Chạy migration từ database V16 có dữ liệu thật sang V17.
6. Chạy SQL 21 rồi SQL 22 trên Supabase sandbox.
7. Kiểm thử RLS bằng anon, user A, user B và admin/service backend.
8. Kiểm thử STT/TTS, quyền micro, lifecycle và audio interruption trên Android/iOS thật.
9. Kiểm thử text scale 90/100/115/130%, narrow screen và system font lớn.
10. Khóa một commit/APK cuối rồi chạy regression onboarding, meal plan, dashboard, notification, auth và cloud sync.
