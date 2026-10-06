Commit de xuat: fix(m31): apply contact RPC migration to QA

# Fix bug — Không lưu được số liên hệ M31

## Triệu chứng và nguyên nhân

App gửi `upsert_sleep_safety_contact` với 8 tham số để lưu contact. Remote
migration history của project QA có hai migration M31 trước, nhưng thiếu
migration `20261006110000_m31_unverified_voice_alert.sql`, migration tạo overload
8 tham số và cột consent tương ứng. Trạng thái triển khai này không bảo đảm
RPC mà app gọi tồn tại.

## Sửa

- Người dùng xác nhận project `rnwohifdnylqfofkydfl` là QA/staging; `.env` và
  APK Android đang cài cùng trỏ tới host của project đó.
- Áp dụng duy nhất migration 11:00 qua `supabase migration up --linked`.
- Không chạy script rebuild/seed, không deploy Edge Function, không đổi cờ và
  không ghi contact, OTP hay cuộc gọi.

## Kiểm chứng backend và source

- Remote migration history khớp ba migration M31 theo thứ tự.
- Truy vấn chỉ đọc xác nhận cột boolean mới `NOT NULL DEFAULT false`, RPC 8
  tham số tồn tại, `authenticated`/`service_role` có quyền execute và `anon`
  không có quyền.
- Flutter focused M31 suite: 33/33 PASS; targeted analyzer: 10 mục, 0 issue.
- `git diff --check`: PASS.

## Chấp nhận trên thiết bị còn mở

- Android hiện trước thao tác là `0/3` contact. APK cài ban đầu là `1.0.1+4`
  và khớp byte-for-byte với APK debug hiện hành.
- ADB touch và UIAutomator đều bị Android từ chối do thiếu `INJECT_EVENTS`.
  Vì không thể bảo đảm xóa contact qua UI, không tạo contact thử; chưa xác nhận
  lưu, tải lại hoặc dọn contact bằng UI.
- Thử chạy integration test tạm thất bại trong bootstrap/teardown và runner đã
  gỡ package app. Đã cài lại đúng APK đã lưu; lần cài hiện tại mới nên đăng
  nhập hoặc cài đặt local có thể cần kiểm tra lại.
- Trong lần thử điều khiển scrcpy, màn hình đã hiển thị độ nhạy đổi từ
  “Cân bằng” sang “Thấp”. Không khôi phục được qua UI trước khi runner gỡ app;
  trạng thái preference trên cloud chưa được xác minh. Cần kiểm tra lại độ
  nhạy sau khi đăng nhập.

## Kết luận

Migration và hợp đồng backend đã được sửa trên QA; chưa có bằng chứng end-to-end
rằng contact hợp lệ lưu được và còn sau khi tải lại. Production, cờ gọi, SMS/Zalo,
OTP và cuộc gọi không bị thay đổi.
