Commit de xuat: docs(ai): record unavailable AI backend route

# Fix kết nối AI — Edge Function route chưa sẵn sàng

## Triệu chứng và bằng chứng

- Ứng dụng hiện tại không gọi Gemini trực tiếp. Các service AI production dùng
  `NabiAiBackendClient` để gọi `nabi-ai-generate` trên Supabase.
- Kiểm tra route `GET /functions/v1/nabi-ai-generate` với cả cấu hình `.env`
  và `assets/config/auth.env` đều nhận HTTP `404`. Hai cấu hình trỏ tới cùng
  public Supabase target; kiểm tra không in URL, anon key hay provider key.
- Một request AI tối thiểu cũng nhận HTTP `404`, vì vậy request chưa tới Edge
  Function và Gemini chưa đọc `GEMINI_API_KEY`.

## Nguyên nhân gốc

Edge Function `nabi-ai-generate` chưa được deploy tại project Supabase đang
được app cấu hình, hoặc endpoint đang trỏ tới project không có function đó.
Đây là lỗi vận hành/deployment, không phải lỗi Flutter không nạp Gemini key.

`GEMINI_API_KEY` cục bộ không thể khắc phục production runtime: app cố ý không
bundle hoặc đọc provider key. Secret này chỉ được `index.ts` của Edge Function
đọc khi function khởi tạo.

## Cách khắc phục cần quyền Supabase

```bash
supabase secrets set GEMINI_API_KEY=... --project-ref "$SUPABASE_PROJECT_REF"
supabase functions deploy nabi-ai-generate --project-ref "$SUPABASE_PROJECT_REF"
```

Sau đó chạy `tools/test_gemini_connection.ps1` từ môi trường có
`SUPABASE_URL` và `SUPABASE_ANON_KEY` đúng. Không đưa `GEMINI_API_KEY` vào
Dart define, Android `BuildConfig` hoặc asset của ứng dụng.

## Phạm vi source

- Đã cập nhật tài liệu current source để bỏ hướng dẫn direct-key đã lỗi thời.
- Không sửa transport Flutter để đưa Gemini key vào client vì sẽ làm lộ secret
  và phá contract release hiện tại.
- Runtime deployment chưa thể hoàn tất trong workspace vì không có Supabase
  access token/project ref hoặc Supabase CLI.

## Xác minh

- Route probe không gọi provider: HTTP `404` trước khi deploy.
- Request kiểm tra tối thiểu: HTTP `404` trước khi provider được gọi.
- Flutter/Dart/PowerShell/Supabase CLI không có trên PATH của workspace; test
  tự động và deployment cần chạy lại trong môi trường có tool/credential.
