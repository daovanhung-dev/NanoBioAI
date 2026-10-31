# Feature - Chuyển NanoBio Mobile và Admin Web sang backend tự host

## Mục tiêu

Chuyển Flutter Mobile và Admin Web khỏi các thao tác Supabase trực tiếp sang API FastAPI có phiên bản; giữ SQLite offline, chuyển luồng AI có tài khoản tới Ollama backend, và cutover dữ liệu sau khi snapshot, restore thử, đối chiếu, HTTPS và migrations sẵn sàng.

## Đã triển khai trong checkout

- Thêm `NANOBIO_API_BASE_URL` và HTTP client có session/refresh, yêu cầu HTTPS ngoài môi trường test.
- Chuyển đăng nhập, đổi mật khẩu, xóa tài khoản và một số thao tác hồ sơ sang API backend; thêm trạng thái bắt buộc đổi mật khẩu cho tài khoản được provision tạm.
- Chuyển cloud snapshot sync, membership/quota, payment requests, Google Play verification, FamilyPlus và một số settings/food evidence/AI report sang route self-hosted.
- AI có tài khoản sử dụng backend cho generate/stream/Food Scan; khách vẫn chạy local. Voice/XiaoZhi không đổi.
- Admin Web bỏ Supabase client/dependency và gọi BackendClient; workflow không còn yêu cầu Supabase credential.
- Backend thêm migrations quota/admin-phone và các route/code cho auth, sync, payment, entitlement và AI text/stream/vision.
- Ollama server đã có `qwen3-vl:4b` local; chưa deploy route vision mới hoặc bật serving cho client.

## Còn thiếu trong phạm vi đã chốt

- Mobile vẫn khởi tạo Supabase và còn direct call ở Admin Mobile, wellness rewards/rank, sale/referral và payout/storage review. Sleep safety datasource đã chuyển sang backend routes trong checkout.
- Admin Web backend chưa có toàn bộ dashboard, sales/reconciliation, reward administration, role permission projection và một số danh sách/bộ lọc nguồn.
- Backend snapshot hiện là allowlist JSON; chưa thay thế toàn bộ side effect/relational contract của Supabase RPC. Sleep safety preferences/session/event owner-scoped sync đã có migration/API nhưng chưa deploy; chưa có history read route. Local migrations `0002`-`0004` chưa áp dụng lên production. Legacy subject/reward eligibility và Sale chưa được port đủ.
- Chưa có công cụ import production đã validate cho toàn bộ 50 account và bảng liên quan; chưa nhập dữ liệu, không dual-write.
- HTTPS chưa sẵn sàng: 80/443 không truy cập được từ Internet. Chứng chỉ IP và cấu hình gia hạn chưa thể nghiệm thu.
- Snapshot `.sql.gpg` chưa được tạo. Máy không có GPG recipient key sẵn và chưa có passphrase riêng; không dùng mật khẩu SSH hoặc khóa mặc định để mã hóa PII.

## Kiểm chứng

- Flutter: 114 test trong nhóm auth/cloud sync/payments/FamilyPlus/config/backend AI pass; riêng AI chat phrase 5 test pass.
- Sleep Safety backend datasource test pass; cả thư mục Sleep Safety có 67 test pass và 1 contract test cũ fail vì vẫn kỳ vọng SQLite version 24 trong khi app hiện dùng version 36.
- Dart analyzer trên tất cả Dart source/test đã sửa: pass. Full `flutter analyze` ghi nhận một warning/error cũ ở dashboard async `BuildContext`; import trùng trong Food Scan prompt đã được sửa.
- Backend Ruff và pytest pass; 2 PostgreSQL-only tests được skip nếu không cấu hình DB test.
- Sleep safety: backend API ownership test và Flutter backend datasource test pass; Alembic `0004` upgrade/check pass trên PostgreSQL 17 fresh schema và mô phỏng schema cũ `0003`.
- Admin Web: 62 test, TypeScript build và Vite build pass trong lần kiểm tra cùng task.
- Snapshot thử restore vào PostgreSQL 17 cô lập: 118 bảng, 0 FK mồ côi, 0 constraint chưa validate; 3/3 Storage object khớp đường dẫn, size và SHA-256.
- Live server health trả 200 qua HTTP cổng 8080; cổng 80 và 443 hiện đóng. Chưa deploy hoặc import production.

## Nguồn trạng thái cutover

`docs/audit/SELF_HOSTED_CUTOVER_CONFLICT_REPORT_2026-10-30.md` ghi số dòng, kết quả va chạm và các điều kiện chặn trước khi import.
