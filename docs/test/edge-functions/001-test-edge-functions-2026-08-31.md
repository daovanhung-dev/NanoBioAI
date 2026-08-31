Commit de xuat: test(edge-functions): kiem tra handler va remote AI smoke

# Test report — Supabase Edge Functions

## Phạm vi

- Ngày: 2026-08-31
- Project: `rnwohifdnylqfofkydfl` / NanoBio
- Mục tiêu: chạy kiểm tra toàn bộ Edge Functions và xác nhận regression fix
  của `nabi-ai-generate`.

## Kết quả

- Handler tests: PASS, 40/40 tests trong 8 nhóm function.
- Type-check: PASS, 9/9 `index.ts` entrypoints.
- Remote functions: PASS, 9/9 functions ACTIVE.
- Deploy: PASS, `nabi-ai-generate` version 5, giữ `verify_jwt=false`.
- Generic smoke: PASS, HTTP 200 với model canonical và `maxOutputTokens=256`.
- Voice-shaped smoke: PASS, HTTP 200 với model không nằm trong allowlist,
  `thinkingLevel` và `maxOutputTokens=256`; xác nhận fallback/config
  normalization hoạt động trên remote.

## Ghi chú an toàn

- Smoke chỉ dùng nội dung giả, không chứa dữ liệu sức khỏe, token hoặc secret.
- Không gọi các function có thao tác tài khoản, membership, thanh toán hoặc
  sleep-safety bằng dữ liệu production.
- Local `supabase functions serve` chưa chạy vì môi trường không có Docker/Podman.
- Giá trị secret không được đọc; chỉ kiểm tra tên secret bằng Supabase CLI.

## Trạng thái

Backend Edge: PASS. Android/Flutter physical E2E của AI Voice vẫn pending.
