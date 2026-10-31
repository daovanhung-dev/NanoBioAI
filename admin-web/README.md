# NanoBio Admin Web

SPA React + TypeScript + Vite cho không gian vận hành Admin NanoBio. Ứng dụng
dùng API FastAPI tự host qua HTTPS; không chứa Supabase key, database URL hoặc
khóa AI.

## Chạy local

```bash
cp .env.example .env.local
# VITE_API_BASE_URL mặc định là https://42.118.174.147
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

- Repository Variable `NANOBIO_API_BASE_URL` (mặc định là `https://42.118.174.147`).

Bật GitHub Pages với source **GitHub Actions**. Admin Web chỉ dùng phiên đăng
nhập backend; workflow không cần Supabase URL hoặc anon key. Quyền truy cập được
kiểm tra lại ở FastAPI trên mọi endpoint quản trị.
