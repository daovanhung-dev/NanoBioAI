# Worklog - HTTPS connection recovery

## Thời gian

- Bắt đầu: 2026-10-30, khoảng 22:45 (Asia/Ho_Chi_Minh)
- Hoàn tất hạ tầng HTTPS: 2026-10-31, khoảng 11:58 (Asia/Ho_Chi_Minh)
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Khôi phục HTTPS công khai cho NanoBio backend và kiểm tra health từ Internet.
- Không thay đổi app, dữ liệu, Supabase hoặc phát hành APK.

## Đã làm

- Giữ Nginx proxy tới FastAPI loopback `127.0.0.1:8000`; PostgreSQL/Ollama không mở ra Internet.
- Cấu hình HTTP-01 webroot tại `/var/www/letsencrypt/.well-known/acme-challenge/`; sau khi người dùng tạo port forwarding, xác minh token ACME từ Internet nhận đúng nội dung với HTTP 200.
- Cấp chứng chỉ Let's Encrypt cho IP `42.118.174.147` bằng Certbot 5.9.0 và profile `shortlived`. Chứng chỉ lưu tại `/etc/letsencrypt/live/42.118.174.147/`, hết hạn 2026-11-06 19:57 UTC.
- Cấu hình Nginx TLS 443 với chứng chỉ IP, redirect HTTP sang HTTPS, giữ ACME trên HTTP, ẩn `/docs`, `/redoc`, `/openapi.json`, giới hạn body 11 MB và tắt response buffering cho `/api/v1/ai/` để hỗ trợ stream.
- Xác nhận `nginx -t` thành công, Nginx active và lắng nghe TCP 80/443; FastAPI vẫn chỉ nghe loopback.
- Xác nhận timer gia hạn Certbot enabled/active; deploy hook reload Nginx chạy thành công; `certbot renew --dry-run` thành công.

## Kiểm tra và giới hạn

- Từ ngoài server, `https://42.118.174.147/health/live` trả HTTP 200 `{"status":"live"}`; `/health/ready` trả HTTP 200 với database ready.
- `openssl s_client -verify_ip 42.118.174.147 -verify_return_error` báo `Verification: OK`; không bỏ qua kiểm tra chứng chỉ.
- HTTP `/health/live` trả 301 tới HTTPS.
- Điện thoại Xiaomi không kết nối ADB trong lượt hoàn tất này; chưa xác nhận UI đăng nhập hoặc đăng nhập end-to-end trên app. Hạ tầng HTTPS và health đã hoạt động. Cần thử đăng nhập trên điện thoại để xác nhận luồng tài khoản thực tế.
- Không sửa hoặc build lại app vì cấu hình hiện có đã trỏ tới `https://42.118.174.147`.

## Tự rà soát

- Không ghi credential/private key vào worklog.
- Không thay đổi database, không chạm các thay đổi Git có sẵn, không dùng `curl -k` hoặc HTTP làm fallback.
- Chứng chỉ IP là loại thời hạn ngắn; timer và dry-run renewal đã được kiểm tra. Lỗi đăng nhập, nếu còn, cần chẩn đoán riêng sau khi kiểm tra trên điện thoại.
