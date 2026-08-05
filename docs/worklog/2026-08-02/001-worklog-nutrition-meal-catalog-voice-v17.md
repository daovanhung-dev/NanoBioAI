Commit đề xuất: feat(nutrition): triển khai hồ sơ, catalog món ăn và voice AI V17

# Worklog - Hồ sơ dinh dưỡng, catalog món ăn và Voice AI V17

## Thời gian

- Ngày: 2026-08-02
- Bắt đầu: 12:24
- Kết thúc: 13:08
- Timezone: Asia/Bangkok (UTC+07:00)

## Phạm vi

- Loại task: coding / Supabase schema / test authoring / static validation.
- Workflow chính: `coding`.
- Task-skill: `.codex/task-skills/coding.md`.
- Domain chính: onboarding/profile assessment.
- Domain liên quan có bằng chứng cross-domain: AI/meal plan, SQLite, Supabase/cloud sync, UI/theme, Nabi/notification.
- Yêu cầu gốc: thực thi `docs/note/02-08-2026.md` theo `PLAN_02-08-2026.md` đã được người dùng xác nhận.

## Quyết định đã khóa

1. Runtime onboarding hiện có 9 bước; màn chọn cỡ chữ đứng trước wizard và không xóa bước nghiệp vụ hiện hữu.
2. 163 công thức được nhập đúng nguồn nhưng không tự suy diễn calories, macro, khẩu phần, dị ứng hoặc chống chỉ định.
3. Công thức nguồn chỉ được AI/đổi món sử dụng sau khi metadata được chuyên gia duyệt (`approved` + `is_plan_eligible`).
4. Supabase cho anon/auth đọc catalog active an toàn; client không được ghi trực tiếp catalog.
5. Voice AI chỉ mở cho người dùng đã xác thực, dùng chung `AIChatRepository`, quota và lịch sử chat hiện tại.
6. Câu chào không tiêu thụ quota; TTS mặc định dùng tiếng Việt của thiết bị.
7. Hồ sơ dinh dưỡng MVP không thu thập trường chuyên gia, liều kê đơn, chữ ký hoặc liên hệ khẩn cấp.
8. Phần “lợi ích” của công thức giữ nguyên nguồn, kèm provenance và cảnh báo không thay thế tư vấn y tế cá nhân.

## Đã triển khai

### Cỡ chữ app-wide

- Thêm bốn preset: 90%, 100%, 115%, 130%.
- Lưu lựa chọn bằng SharedPreferences và dùng một source-of-truth cho V1, V2, V3, Admin và app hợp nhất.
- Kết hợp với text scale hệ thống, giới hạn hiệu lực 0.90–1.60.
- Thêm gate trước onboarding và bộ chỉnh trong Settings.
- Chuẩn hóa casing các đường dẫn asset Nabi trong `pubspec.yaml` và khai báo riêng `assets/data/` để catalog JSON được đóng gói trên hệ điều hành phân biệt hoa/thường.

### Hồ sơ dinh dưỡng có cấu trúc

- Thêm entity/repository/datasource/controller/provider và giao diện 5 chặng ngắn.
- Lưu toàn bộ hồ sơ trong một transaction.
- Hỗ trợ: thông tin nền, hạn chế thực phẩm, triệu chứng, thuốc/sản phẩm bổ sung, xét nghiệm, tối đa ba mục tiêu, giờ ăn và quy tắc ưu tiên/tránh.
- Thêm route bảo vệ và entry point từ Nutrition/Profile.

### SQLite V17 và cloud sync

- Nâng `DatabaseVersion.currentVersion` từ 16 lên 17.
- Thêm tám bảng user-owned: `nutrition_profiles`, `health_symptoms`, `medication_records`, `food_restrictions`, `lab_results`, `nutrition_goals`, `meal_schedule_preferences`, `nutrition_preference_rules`.
- Mở rộng `meal_catalog` với metadata, provenance, trạng thái duyệt và eligibility.
- Mở rộng `meal_plans` với snapshot công thức, provenance và số lần đổi món.
- Bổ sung migration additive/idempotent, onCreate, outbox trigger và cloud snapshot mapping.

### Catalog 163 công thức

- Tạo importer/validator deterministic từ `Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md`.
- Sinh `assets/data/meal_catalog_v1.json` gồm 163 công thức thuộc 64 chủ đề và 11 chương.
- Sinh SQL seed Supabase tương ứng.
- Giữ nguyên nguyên liệu, bước chế biến, lợi ích và provenance; các trường không có trong nguồn để `null`/trạng thái chờ duyệt.

### AI meal plan và đổi món

- Tạo `MealCandidateSelector` dùng chung cho AI, local fallback và đổi món.
- Chỉ nhận món active, đúng meal type, metadata/constraint đã duyệt và `is_plan_eligible=true`.
- Loại ứng viên theo dị ứng, không dung nạp, quy tắc tránh và condition tags có cấu trúc.
- AI tiếp tục trả `meal_code`; app hydrate snapshot từ catalog, không tin tên món/nội dung tự do từ model.
- Thêm bottom sheet chi tiết công thức và nút đổi món có xác nhận.
- Đổi món cập nhật `meal_plans` và item timeline liên kết trong cùng transaction, sau đó refresh reminder/provider.

### Supabase catalog cache

- Thêm SQL V17 cho bảng/RLS/RPC/snapshot và seed catalog.
- Thêm dịch vụ tải catalog active từ Supabase vào SQLite theo cơ chế last-good local cache.
- Cache refresh chạy sau khi Supabase khởi tạo thành công; lỗi không xóa catalog local đang dùng.

### Voice AI

- Thêm `speech_to_text` và `flutter_tts`.
- Thêm quyền microphone/speech recognition cho Android và iOS.
- Thêm route `/ai-voice`, CTA từ AI Chat, STT `vi_VN`, TTS `vi-VN`, chào tự động, mute, replay, stop và fallback nhập chữ.
- Dùng cùng `AIChatRepository`, do đó giữ quota, persistence và policy hiện hữu.
- Dùng operation token để bỏ response cũ; dừng STT/TTS khi app paused/inactive/detached hoặc page dispose.
- Map trạng thái voice sang animation Nabi hiện có.

## Test đã bổ sung

- `test/core/theme/app_text_scale_test.dart`
- `test/core/storage/localdb/migration_v17_test.dart`
- `test/app_versions/v1/features/nutrition/nutrition_profile_local_datasource_test.dart`
- `test/app_versions/v1/features/meal_plan/meal_candidate_selector_test.dart`
- `test/app_versions/v1/features/meal_plan/meal_plan_snapshot_normalizer_test.dart`
- `test/app_versions/v1/features/meal_plan/meal_plan_replacement_transaction_test.dart`
- `test/app_versions/v1/features/ai_voice/ai_voice_controller_test.dart`
- `test/docs/supabase_nutrition_v17_contract_test.dart`

## Validation đã thực hiện

- Recipe import/validation: PASS — 163 công thức, 64 chủ đề, fidelity nguồn hợp lệ.
- Python syntax cho importer/validator: PASS.
- Dart lexical delimiter và local/package import resolution trên 64 file Dart thay đổi: PASS tĩnh.
- AndroidManifest XML parse: PASS.
- iOS Info.plist parse: PASS.
- Pubspec YAML/JSON asset parse: PASS.
- SQLite/Supabase table, outbox và catalog seed contract scan: PASS tĩnh.
- Kiểm tra file nhạy cảm trong gói bàn giao: PASS — loại `.env`, `assets/config/auth.env`, keystore và cache.

## Validation chưa thể chạy

- `dart format`: SKIPPED — môi trường không có Dart SDK.
- `flutter analyze`: SKIPPED — môi trường không có Flutter SDK.
- `flutter test`: SKIPPED — môi trường không có Flutter SDK.
- `flutter build apk --debug`: SKIPPED — không có Flutter/Android toolchain.
- Test trên thiết bị thật: SKIPPED — không có thiết bị kết nối.
- Supabase local/sandbox và RLS multi-user: SKIPPED — không có backend sandbox/config an toàn trong môi trường.
- `.codex/tools/update_worklog_learning.ps1`: SKIPPED — không có PowerShell; history được cập nhật thủ công.

## Trình tự triển khai backend

1. Backup database/sandbox.
2. Chạy `docs/supabase/21-nutrition-profile-meal-catalog-v17.sql`.
3. Chạy `docs/supabase/22-meal-catalog-source-seed.sql`.
4. Chạy contract/RLS checks với anon, user A, user B và service backend.
5. Chỉ bật `is_plan_eligible=true` sau khi metadata dinh dưỡng và constraint được duyệt.
6. Phát hành app để SQLite tự migrate V16 -> V17.

## Rủi ro còn mở

- V17 SQL/RLS chưa được chạy trên sandbox/staging.
- STT/TTS và native permissions chưa được kiểm thử trên thiết bị Android/iOS thật.
- 163 công thức nguồn chưa đủ metadata chuyên môn để dùng tự động trong meal plan.
- Compile/analyze/test chưa có bằng chứng runtime do thiếu Flutter SDK trong môi trường thực thi.

## Tỷ lệ hoàn thành

- Hoàn thành: source code, SQLite migration, Supabase contract, catalog import, UI, test authoring, static validation và gói bàn giao.
- Chưa chứng nhận: compile/runtime/device/backend sandbox.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: thay đổi bám architecture boundary; catalog y tế không tự suy diễn dữ liệu thiếu.
- Mức độ hoàn thành: toàn bộ phạm vi code trong plan đã được triển khai; phần chứng nhận runtime bị giới hạn bởi toolchain.
- Bằng chứng kiểm chứng: importer fidelity, schema/manifest/parser checks, changed-file lexical/import scan và test source.
- Điểm chưa tối ưu: task cross-domain lớn; cần một môi trường Flutter khóa version để giảm rủi ro compile API.
- Cách tối ưu phiên sau: chạy targeted analyze/tests trước, sau đó migration test, Supabase RLS matrix, APK build và device acceptance theo một commit/APK khóa.
