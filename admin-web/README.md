# NanoBio Admin Web

SPA React + TypeScript + Vite cho không gian vận hành Admin NanoBio. Ứng dụng
dùng Supabase Auth hiện có, các RPC/Edge Function được cấp quyền và bucket
`sale-payout-proofs`; không chứa service-role key, database URL hoặc Gemini key.

## Chạy local

```bash
cp .env.example .env.local
# điền VITE_SUPABASE_URL và VITE_SUPABASE_ANON_KEY
npm install
npm run dev
```

Các lệnh kiểm tra:

```bash
npm run typecheck
npm test
npm run build
```

SPA dùng `HashRouter`, vì vậy các route nằm dưới `/admin/*` vẫn khôi phục được
khi refresh trên GitHub Pages. Build production dùng base `/NanoBioAI/` và sẽ
được publish tại `https://daovanhung-dev.github.io/NanoBioAI/` sau khi workflow
Pages hoàn tất.

## Cấu hình GitHub Actions

Trong repository, tạo:

- Repository Variable `NANOBIO_SUPABASE_URL`.
- Repository Secret `NANOBIO_SUPABASE_ANON_KEY`.

Bật GitHub Pages với source **GitHub Actions**. Anon/publishable key và URL có
thể xuất hiện trong bundle frontend; RLS, permission check và RPC security
definer ở Supabase mới là lớp bảo vệ dữ liệu cuối cùng. Chỉ tài khoản có
`get_my_admin_session` hợp lệ mới vào được khu Admin.

Workflow không chạy các thao tác schema, không quản lý secret Supabase và không
được xem là bằng chứng backend production-ready. Contract test Supabase vẫn
cần chạy trong môi trường có Dart/Supabase runtime phù hợp.
