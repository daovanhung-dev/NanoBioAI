Commit de xuat: fix(m31): dong bo contact va dispatch giám sát giấc ngủ

# Fixbug - M31 contact và liên hệ hỗ trợ giấc ngủ

## Hiện tượng

- Contact đã lưu qua RPC nhưng danh sách có thể vẫn rỗng hoặc quay về cache cũ.
- Khi người dùng bấm “Tôi cần hỗ trợ”, lỗi native acknowledgement có thể chặn dispatch cloud.
- Dispatch có thể chạy khi session/event chưa kịp đồng bộ lên Supabase.
- UI giữ spinner ở trạng thái escalating sau khi provider accepted hoặc failed.

## Nguyên nhân

- Controller bỏ qua `SafetyContact` trả về từ RPC rồi gọi một refresh không có cơ chế chống kết quả stale.
- `saveSession`/`saveEvent` trước đây chỉ đồng bộ cloud best-effort; Edge Function đọc dữ liệu server nên không thấy event mới.
- `requestHelp` chờ native response trước khi chuyển sang cloud dispatch.
- Machine state không được kết thúc ở accepted/failed và native chưa có lệnh dismiss cảnh báo.

## Phạm vi sửa

- Merge ngay contact RPC vào state và SQLite cache; refresh có generation guard; tự chọn priority còn trống cho contact mới.
- Validate tên, mối quan hệ, E.164/đầu số Việt Nam và mã OTP; map lỗi RPC/Edge thành copy tiếng Việt.
- Dispatch bắt buộc sync session rồi event, retry sync/provider với cùng idempotency key; không gọi provider nếu sync thất bại.
- Native acknowledgement là best-effort; thêm `dismissAlert` Android/iOS sau khi server accepted.
- UI hiển thị riêng đang liên hệ, thất bại và nút thử lại; accepted không để spinner vô hạn.
- Không đổi chữ ký RPC/schema, không gọi 115, vẫn yêu cầu contact verified và gói Plus/FamilyPlus.

## Kiểm thử và trạng thái nghiệm thu

- Deno verification/dispatch handlers: PASS 4/4.
- Flutter focused unit/regression: PASS 15/15.
- `dart format`: PASS trên các file M31; `flutter analyze`: PASS toàn dự án.
- Android debug APK: PASS; đã cài và khởi chạy trên thiết bị thật `12b304f9` (`220333QPG`), logcat PID ứng dụng không có `FATAL EXCEPTION`/`AndroidRuntime`.
- Android thật đã nhận diện: model `220333QPG`, serial `12b304f9`.
- Luồng contact/OTP/dispatch trên UI thật: `UNVERIFIED/BLOCKED` tại màn hình đăng nhập vì chưa có credential/OTP test được cung cấp.
- Supabase Edge Functions đang `ACTIVE`, nhưng provider secret `SLEEP_SAFETY_PROVIDER_BASE_URL` và `SLEEP_SAFETY_PROVIDER_TOKEN` chưa được cấu hình; voice/SMS thực tế chưa thể xác nhận.
- Local Supabase status: `BLOCKED` do môi trường không có Docker/Podman; không ảnh hưởng việc kiểm tra remote function list.

## Giới hạn

- Không ghi secret provider hoặc OTP vào tài liệu/log.
- Nếu thiếu Supabase Edge runtime/provider secret, trạng thái cuối phải là `UNVERIFIED/BLOCKED`, không được đánh dấu hoàn tất.
