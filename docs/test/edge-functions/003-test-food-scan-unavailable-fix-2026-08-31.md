Commit de xuat: test(food-scan): xac minh fix khong dung duoc

# Test - Food Scan unavailable fix

## Kết quả

- `deno test --no-lock supabase/functions/food-scan-analyze/handler_test.ts`:
  PASS - 11/11.
- Toàn bộ Edge handler tests: PASS - 51/51.
- Toàn bộ Edge `index.ts` qua `deno check --no-lock`: PASS - 10/10.
- `deno fmt --check` cho các Edge files đã chạm: PASS.
- `git diff --check`: PASS.
- Deploy `food-scan-analyze`: PASS - version 3.
- Remote function list: `food-scan-analyze` `ACTIVE`, `verify_jwt=true`.
- Remote không Authorization: PASS - HTTP 401 gateway.
- Remote anon token: PASS - HTTP 401 `AUTHENTICATION_REQUIRED` từ handler.

## Regression coverage

- FamilyPlus không còn bị app gate chặn bởi `isPlus`.
- Ảnh local được encode JPEG dưới `FoodScanImageService.maxEncodedBytes` và
  không còn EXIF.

## Chưa chạy được

`flutter test`, `flutter analyze` và `dart format` bị bỏ qua vì Flutter/Dart SDK
không có trong workspace. Success path `vision`/`health` cần token của tài khoản
Plus/FamilyPlus thật; token phải truyền qua biến môi trường tạm thời và không ghi
vào log/repo.
