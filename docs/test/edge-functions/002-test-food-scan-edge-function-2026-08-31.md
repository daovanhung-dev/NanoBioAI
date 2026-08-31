Commit de xuat: test(food-scan): xac minh edge function phan tich mon an

# Test - Food Scan Edge Function

## Phạm vi

- Handler validation/auth/access/rate limit/provider contract.
- Shared Gemini model/config normalization.
- Supabase remote deployment và auth boundary.
- Flutter contract được kiểm tra bằng source assertion; Flutter SDK không có
  trong workspace nên chưa chạy được Flutter test/analyze.

## Kết quả

- `deno test --no-lock supabase/functions/food-scan-analyze/handler_test.ts`:
  PASS - 11/11.
- Toàn bộ `supabase/functions/**/handler_test.ts`: PASS - 51/51.
- Toàn bộ Edge Function `index.ts` qua `deno check --no-lock`: PASS - 10/10.
- `deno fmt --check` cho các file Edge đã chạm: PASS.
- `git diff --check`: PASS.
- `supabase functions deploy food-scan-analyze --project-ref rnwohifdnylqfofkydfl --use-api`:
  PASS.
- Remote `supabase functions list`: `food-scan-analyze` ACTIVE, version 2,
  `verify_jwt=true`.
- Remote POST không có Authorization header: PASS - HTTP 401 với gateway
  `UNAUTHORIZED_NO_AUTH_HEADER`.
- Remote POST dùng anon token không phải user session: PASS - HTTP 401 với
  `AUTHENTICATION_REQUIRED` từ handler.

## Chưa xác minh

Chưa chạy được remote success path `vision`/`health` với tài khoản Plus vì
workspace không có access token người dùng an toàn. Không tạo user hoặc
membership giả trên project remote. Cần chạy bổ sung với token Plus truyền qua
biến môi trường tạm thời, không ghi vào repo hoặc log.
