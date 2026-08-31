Commit de xuat: fix(food-scan): khac phuc gate va payload anh

# Worklog - Food Scan không dùng được

## Thoi gian

- Ngay: 2026-08-31
- Bat dau: 06:00
- Ket thuc: 06:27
- Timezone: Asia/Ho_Chi_Minh (UTC+07:00)

## Pham vi

- Loai task: bugfix
- Module chinh: V3 Food Scan / AI backend / membership gate
- Yeu cau goc: fix lỗi không dùng được chức năng phân tích món ăn.

## Da lam

- Truy nguyên đường đi `FoodScanAccessProvider -> FoodScanImageService -> NabiAiBackendClient -> food-scan-analyze`.
- Xác nhận mismatch `isPlus` ở app và `plus/family_plus` ở Edge Function.
- Xác nhận ảnh cuối chưa có byte budget tương ứng với giới hạn base64/request của
  Edge Function.
- Đổi gate sang `hasPaidAccess`.
- Thêm JPEG compression loop, xóa EXIF/GPS và regression test ảnh.
- Cập nhật UI/copy và tài liệu fixbug/test/feature.
- Redeploy Edge Function version 3 và kiểm tra auth boundary remote.

## File code/docs da sua

- `lib/app_versions/v3/features/food_scan/providers/food_scan_providers.dart`
- `lib/app_versions/v3/features/food_scan/data/services/food_scan_image_service.dart`
- `lib/app_versions/v3/features/food_scan/domain/food_scan_exception.dart`
- `lib/app_versions/v3/features/food_scan/presentation/pages/food_scan_page.dart`
- `test/app_versions/v3/features/food_scan/food_scan_access_contract_test.dart`
- `test/app_versions/v3/features/food_scan/food_scan_image_service_test.dart`
- `supabase/functions/food-scan-analyze/handler.ts`
- `docs/features/food-scan/001-feature-food-scan-edge-function.md`
- `docs/fixbug/food-scan-unavailable/001-fixbug-food-scan-unavailable.md`
- `docs/test/edge-functions/003-test-food-scan-unavailable-fix-2026-08-31.md`

## Commands

- `deno test --no-lock supabase/functions/food-scan-analyze/handler_test.ts`:
  PASS - 11/11.
- `find supabase/functions -type f -name handler_test.ts -print0 | xargs -0 deno test --no-lock`:
  PASS - 51/51.
- `find supabase/functions -type f -name index.ts -print0 | xargs -0 deno check --no-lock`:
  PASS - 10/10.
- `deno fmt --check ...`: PASS.
- `git diff --check`: PASS.
- `supabase functions deploy food-scan-analyze --project-ref rnwohifdnylqfofkydfl --use-api`:
  PASS - version 3.
- `supabase functions list --project-ref rnwohifdnylqfofkydfl`: PASS - function
  `ACTIVE`, `verify_jwt=true`.
- Remote no-auth/anon smoke: PASS - lần lượt HTTP 401 gateway và handler.
- `flutter test`, `flutter analyze`, `dart format`: UNVERIFIED - Flutter/Dart SDK
  không tồn tại trong workspace.

## Loi/Rui ro

- Đã fix: FamilyPlus không còn bị chặn sai ở app; ảnh chuẩn bị từ camera/gallery
  không còn vượt payload budget đã đặt cho Food Scan.
- Chưa xác minh: remote success path `vision`/`health` với token Plus/FamilyPlus
  thật và Flutter physical-device E2E.
- Giữ nguyên các thay đổi AI Voice đang có trong worktree.

## Ty le hoan thanh

- Hoàn thành: root-cause patch, regression coverage, Edge validation, deploy và
  auth boundary smoke.
- Còn pending: Flutter/Dart test/analyze và authorized remote success smoke do
  thiếu toolchain/token hợp lệ.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - patch đi đúng hai điểm chặn đã xác nhận, đồng bộ app/server và có regression test.
- Muc do hoan thanh task: partial - fix đã deploy; success path cần token paid và Flutter SDK để xác nhận cuối.
- Bang chung kiem chung: Edge 51/51, 10 entrypoints type-check, deploy version 3 ACTIVE, remote 401 boundary PASS.
- Diem ton token/chua toi uu: chưa có Flutter runtime và paid test account nên không chứng minh được E2E.
- Cach toi uu cho phien sau: cấp Flutter/Dart SDK và token test tạm qua biến môi trường để chạy authorized smoke ngay sau deploy.
- Task-skill can doc lan sau: `.codex/task-skills/bugfix.md`
