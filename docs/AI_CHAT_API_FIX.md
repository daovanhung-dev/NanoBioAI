# NanoBio — Kết nối AI Chat

> Ghi chú current source (2026-08-29): hướng dẫn direct Gemini key trước đây
> đã được thay thế bằng transport backend-only để không đóng gói provider key
> trong ứng dụng.

## Luồng hiện tại

```text
Flutter -> Supabase Edge Function `nabi-ai-generate` -> Gemini
```

`AIChatService` gọi `NabiAiBackendClient` trong production. `GEMINI_API_KEY`
không được đọc từ `.env`, Dart define, Android `BuildConfig` hoặc Flutter asset
cho ứng dụng phát hành. Key chỉ tồn tại ở Edge Function secret.

## Cấu hình và triển khai đúng

1. Cấp `SUPABASE_URL` và `SUPABASE_ANON_KEY` công khai của đúng project cho
   app build/runtime.
2. Với quyền quản trị Supabase, đặt provider key ở server và deploy function:

```bash
supabase secrets set GEMINI_API_KEY=... --project-ref "$SUPABASE_PROJECT_REF"
supabase functions deploy nabi-ai-generate --project-ref "$SUPABASE_PROJECT_REF"
```

3. Xác minh từ môi trường có cấu hình public Supabase bằng:

```powershell
powershell -ExecutionPolicy Bypass -File tools/test_gemini_connection.ps1
```

Script chỉ báo trạng thái/độ dài phản hồi, không in secret. Nó gọi Edge
Function nên chỉ chạy sau khi đã có quyền và chấp nhận một request kiểm tra.

## Khi ứng dụng báo không thể kết nối

- HTTP `404` ở `/functions/v1/nabi-ai-generate` nghĩa là function chưa có ở
  project đang được cấu hình hoặc app đang trỏ nhầm project; Gemini key chưa
  được dùng tới ở bước này.
- HTTP `502` sau khi function đã tồn tại cần được kiểm tra trong Edge Function
  logs: secret provider thiếu/sai, model server-side không khả dụng, quota hoặc
  provider tạm thời lỗi.
- Không sửa bằng cách đưa `GEMINI_API_KEY` vào APK. Điều đó trái với contract
  bảo mật hiện tại và không sửa deployment phía server.

Không commit provider key, service-role key, session token hoặc `.env` thật.
