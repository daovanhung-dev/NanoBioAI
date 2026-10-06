# Production checklist

- [ ] Chạy `node tests/smoke.js` không lỗi.
- [ ] Deploy migration `20261006_early_access.sql`.
- [ ] Deploy `register-early-access` với `verify_jwt=false`.
- [ ] Đặt `ALLOWED_ORIGINS` đúng domain production.
- [ ] Upload APK thật vào private bucket `early-access-apk/nanobio-early-access.apk`.
- [ ] Ghi SHA-256 của APK vào release note/site nếu cần.
- [ ] Đặt `APP_VERSION` đúng build.
- [ ] Đổi `allowDemoFallback=false` trước khi go-live chính thức.
- [ ] Kiểm tra CTA **Tải ứng dụng miễn phí** mở popup SĐT đúng luồng.
- [ ] Kiểm tra SĐT test tạo/cập nhật lead với `promotion_code=EARLY_ACCESS_PLUS_30D`, `requested_plan=plus`, `vip_duration_days=30`.
- [ ] Xác nhận không đọc được bảng từ anon key.
- [ ] Kiểm tra signed URL hết hạn theo cấu hình.
- [ ] Xác nhận quyền sử dụng ảnh chuyên gia bên ngoài repository trước khi thêm ảnh.
- [ ] Kiểm tra mobile 360px, tablet, desktop.
- [ ] Kiểm tra keyboard navigation và reduced motion.

- [ ] Có quy trình vận hành đối chiếu SĐT → tài khoản NanoBio → kích hoạt Plus 30 ngày bằng backend/Admin trusted flow.
- [ ] Không quảng bá FamilyPlus như một phần của ưu đãi VIP 1 tháng.
- [ ] Advanced Health Tracking / Goal Roadmap tiếp tục gắn nhãn đang hoàn thiện cho đến khi runtime acceptance hoàn tất.
