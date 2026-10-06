# Worklog — Khôi phục trang chủ khi cloud sync lỗi

- Ngày: 2026-10-06
- Loại task: bugfix
- Module chính: v1 dashboard / v2 cloud sync
- Yêu cầu: sửa dashboard trên Xiaomi khi SQLite trống và cloud pull đang chờ;
  bảo toàn tài khoản, không xóa dữ liệu hoặc tạo hồ sơ giả.

## Nguyên nhân và thay đổi

Dashboard datasource chỉ đọc hồ sơ trong SQLite theo UID hiện tại. Trên máy QA,
SQLite v26 có `integrity_check=ok` nhưng không có hàng `users`/`health_profiles`;
phiên đăng nhập còn lưu và `cloud_pull_retry_pending=true`. Nút lỗi cũ chỉ
invalidate hai provider local nên không thử cloud.

Read-only request bằng phiên QA tới đúng staging ref cho thấy tài khoản có hàng
`users` và `health_profiles`. Snapshot thất bại vì
`public.fitness_training_programs` chưa có trong schema cache (`PGRST205`), dù
bảng được liệt kê trong client pull contract.

Nút **Thử lại** giờ làm mới trạng thái outbox/cờ pull, gọi controller `retry()`
khi pull/upload còn pending, rồi tải lại dashboard và dữ liệu động. Việc đọc cờ
bền vững vẫn diễn ra khi controller đang `syncing`; repository hiện có coalesce
sync requests đang chạy. Remote sync bỏ qua riêng bảng optional khi đúng lỗi
`PGRST205`; SQLite giữ rows của bảng vắng trong snapshot, còn bảng rỗng tường
minh vẫn đồng bộ theo cloud. Khi lỗi khác, app giữ account/data và đưa hướng
dẫn phục hồi. Thêm Material riêng cho ExpansionTile dashboard sau khi
regression render phát hiện assertion Flutter ẩn trong trạng thái ready.

## Kiểm chứng

- Focused `flutter test --no-pub`: dashboard recovery (3), dashboard local
  datasource (2), authenticated sync repository (8), SQLite replacement (3),
  remote datasource (1) — 17/17 PASS.
- `flutter analyze --no-pub`: `No issues found!`.
- `flutter build apk --debug --no-pub -t lib/main.dart
  --dart-define-from-file=.dart_tool/nanobio_defines.json`: PASS, project ref
  trong runtime config khớp staging ref do người dùng cung cấp. Không in khóa.
- `adb install -r`: PASS; không uninstall/clear data. Xiaomi model 220333QPG,
  API 30, package version 1.0.1/code 4.
- Sau cài bản cuối, sync startup đã khôi phục hồ sơ; SQLite v26 vẫn
  `integrity_check=ok`, `users=1`, `health_profiles=1`; cờ
  `cloud_pull_retry_pending=false`. Dashboard render đầy đủ.
- Quét logcat sau khôi phục: không có fatal exception, AndroidRuntime error
  hoặc Flutter error.
- Trước khi sửa bảng optional, lần chạm **Thử lại** trên bản trung gian vẫn
  thất bại vì bảng remote thiếu. Sau bản sửa cuối, startup sync tự phục hồi trước
  khi cần chạm nút; regression widget test bao phủ hành vi nút trên state
  `syncing`.
- ADB không được `INJECT_EVENTS`; không chạy integration runner, không chạm UI
  bằng shell. Không chạy Auth controller test timeout từ lượt chẩn đoán.
- Không đổi schema, dữ liệu staging hoặc Edge Function.

## Trạng thái

Source, regression tests, analyze, build và kiểm tra thực trên Xiaomi đã xong.
Trang chủ đã mở, hàng hồ sơ được khôi phục, cờ pull được xóa và không thấy crash.

## Tự đánh giá

- Đã tái hiện nguyên nhân bằng response `PGRST205` của staging và thêm regression
  cho state `syncing` cùng cờ pull bền vững.
- Giữ API backend/schema và dữ liệu staging không đổi; bỏ qua duy nhất projection
  optional chưa tồn tại và bảo toàn local rows khi snapshot không có khóa bảng.
- Các lượt sau cần giữ cảnh báo nếu staging vẫn chưa triển khai
  `fitness_training_programs`; không đánh đồng thiếu bảng này với lỗi các bảng
  hồ sơ bắt buộc.
