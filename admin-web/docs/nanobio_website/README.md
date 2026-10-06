# NanoBio / Nabi — Website tải miễn phí + VIP 1 tháng

Website được dựng theo `BD-NANOBIO-WEB-EARLY-ACCESS-001` ngày 2026-10-06.

## Có gì trong sản phẩm

- Landing page responsive hoàn chỉnh: Hero → Giới thiệu → Nabi → Tính năng → Điểm nổi bật → Người đồng hành/Ban khoa học → Gallery → Quyền lợi VIP → CTA tải miễn phí → popup SĐT → Hướng dẫn cài → FAQ → Disclaimer.
- Nội dung chức năng được gắn trạng thái `Đang có / Một phần / Đang phát triển` theo BD.
- Ảnh người đồng hành và screenshot được lấy từ repository `daovanhung-dev/NanoBioAI` qua raw GitHub URL, có fallback UI nếu ảnh tạm thời không tải được.
- Form SĐT chỉ xuất hiện sau khi khách bấm **Tải ứng dụng miễn phí**; có validation số di động Việt Nam, consent, trạng thái loading/error/success.
- Tích hợp Supabase Edge Function production và migration Postgres/RLS; mỗi đăng ký được ghi nhận với promotion `EARLY_ACCESS_PLUS_30D`, plan nội bộ `plus`, thời hạn ưu đãi 30 ngày.
- Bucket APK private + signed URL.
- Chế độ Demo local có nhãn rõ ràng để website vẫn test được trước khi backend được deploy.
- GitHub Pages workflow, privacy page, PWA manifest, mobile menu, accessibility, reduced motion.


## Flow kinh doanh hiện tại

```text
Khách xem nội dung / tính năng / chuyên gia / giao diện
→ kéo tới cuối trang
→ xem rõ Free khác VIP ở đâu
→ bấm “Tải ứng dụng miễn phí”
→ popup yêu cầu SĐT
→ đồng ý mục đích sử dụng SĐT
→ backend ghi nhận Early Access + quyền nhận Plus/VIP 30 ngày
→ trả signed URL APK nếu file đã được upload
→ đội ngũ đối chiếu SĐT với tài khoản NanoBio để kích hoạt quyền Plus 30 ngày
```

**Quy ước:** “VIP 1 tháng” là tên ưu đãi marketing trên website. Hệ thống không tạo tier VIP mới; quyền được ánh xạ sang **Plus 30 ngày**. FamilyPlus không nằm trong ưu đãi.

### Quyền lợi VIP/Plus hiển thị trên web

- AI Chat không giới hạn (Free: 3 lượt/ngày).
- Tạo lịch trình AI không giới hạn (Free: 3 lượt/tháng).
- Quyền Plus cho Advanced Health Tracking khi module khả dụng.
- Quyền Plus cho Goal Roadmap khi module khả dụng.

Hai module nâng cao cuối được ghi rõ **đang hoàn thiện**, không quảng cáo như chức năng runtime hoàn tất.

## Chạy ngay

Không cần npm/build step:

```bash
cd nanobio_website
python3 -m http.server 8080
```

Mở `http://localhost:8080`.

Hoặc:

```bash
npx http-server . -p 8080
```

## Kiểm thử

```bash
node tests/smoke.js
```

## Backend Supabase production

Public client config đang dùng đúng URL + anon key đã có trong `NanoBioAI/assets/config/auth.env`. **Không có service-role key trong frontend.**

Để bật lưu SĐT thật + ghi nhận ưu đãi Plus/VIP 30 ngày + signed APK URL:

```bash
supabase login
./scripts/setup-supabase.sh
```

Sau đó cấu hình secrets cho Edge Function (ví dụ):

```bash
supabase secrets set \
  ALLOWED_ORIGINS="https://<domain-cua-ban>" \
  EARLY_ACCESS_BUCKET="early-access-apk" \
  EARLY_ACCESS_APK_PATH="nanobio-early-access.apk" \
  APP_VERSION="1.0.1+4" \
  SIGNED_URL_SECONDS="900"
```

Upload APK thật vào **private bucket** `early-access-apk`, path `nanobio-early-access.apk`.

> Supabase tự cung cấp `SUPABASE_URL` và `SUPABASE_SERVICE_ROLE_KEY` cho Edge Function runtime. Không đưa service-role key vào website.

Sau khi backend đã deploy ổn định, đổi `allowDemoFallback` thành `false` trong `assets/js/config.js` để production không bao giờ rơi về local demo.

## GitHub Pages

Repo có `.github/workflows/deploy-pages.yml`. Đẩy toàn bộ thư mục này thành root của repo website rồi bật **Settings → Pages → Source: GitHub Actions**.

## Tài nguyên

Website hiện dùng remote source asset từ repository chính để tránh sao chép sai nguồn. Các đường dẫn có thể được mirror sang `/assets/` về sau nếu muốn loại bỏ phụ thuộc raw GitHub.

## Quan trọng về “100% production”

Phần frontend, modal tải app, validation, UX, privacy page, Supabase migration, Edge Function ghi nhận quyền nhận Plus/VIP 30 ngày và deployment workflow đều hoàn chỉnh. Hai yếu tố bên ngoài không thể tự sinh từ BD là:

1. **APK thật** — repository hiện không có `.apk/.aab` hay GitHub Release; cần upload build APK chính thức vào bucket.
2. **Deploy backend** — cần quyền Supabase của chủ project để chạy migration/function deployment.

Trước hai bước đó website tự chuyển sang **Demo local có nhãn rõ**, không giả vờ đã lưu dữ liệu lên server.
