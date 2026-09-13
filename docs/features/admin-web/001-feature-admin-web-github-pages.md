Commit đề xuất: feat(admin-web): tạo workspace vận hành NanoBio trên GitHub Pages

# NanoBio Admin Web trên GitHub Pages

## Mục tiêu

- Tạo SPA Admin độc lập trong `admin-web/` cho các luồng vận hành hiện có.
- Giữ Supabase Auth, RPC, Edge Function và Storage là backend duy nhất.
- Publish static bundle bằng GitHub Actions với `HashRouter` và base `/NanoBioAI/`.

## Phạm vi đã triển khai

- Dashboard, users/account, payments/membership review, Sale, Sale conversions,
  wellness rewards, reconciliation, plans, reports, audit và config.
- Permission-aware navigation/action theo `get_my_admin_session` với 5 nhóm
  role hiện hành: Super, Finance, Support, Content và Operations Admin.
- Adapter typed cho RPC list/detail/mutation, Edge Function tạo tài khoản/cấp
  membership, và bucket `sale-payout-proofs`.
- Write flow có reason, confirmation, idempotency key, guard chống gửi trùng,
  refresh sau khi backend trả thành công; duyệt payment bắt buộc xác nhận đã
  đối chiếu chuyển khoản.
- Không hiển thị raw payment payload, raw metadata, password, secret hoặc
  stack trace; mã ưu đãi chỉ dùng dữ liệu đã mask từ RPC wellness.

## Backend contract

Đã đối chiếu chữ ký RPC trong canonical `docs/supabase/01_build_system.sql`,
đặc biệt payment reviewer có `p_transfer_verified`, danh sách wellness trả
shape riêng, và policy bucket chỉ cho insert/đọc trong path conversion. Không
thay đổi schema hoặc mở CRUD trực tiếp từ frontend.

## Deploy

Workflow `.github/workflows/deploy-admin-web.yml` chạy khi `admin-web/**` thay
đổi, thực hiện `npm ci`, typecheck, test, build và deploy `admin-web/dist` lên
GitHub Pages. Cần tạo Repository Variable `NANOBIO_SUPABASE_URL` và Repository
Secret `NANOBIO_SUPABASE_ANON_KEY`; không đưa service-role key lên Pages.

## Giới hạn và bằng chứng

- Frontend build/test đã chạy trong workspace; asset production được kiểm tra
  dưới `/NanoBioAI/assets/...`.
- Chưa có Dart/Flutter hoặc Supabase runtime trong môi trường này, nên chưa
  chạy lại contract tests Supabase hiện hữu và chưa claim production-ready.
- Deploy thực tế cần push workflow lên `main`, bật Pages source là GitHub
  Actions, rồi kiểm tra log của GitHub Actions và RLS/RPC trên môi trường đích.
