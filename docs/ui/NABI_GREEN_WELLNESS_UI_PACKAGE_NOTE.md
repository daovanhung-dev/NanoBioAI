# Ghi chú gói bàn giao — NaBi Green Wellness UI

## Nội dung gói

- Source Flutter/Dart hiện có trong archive người dùng cung cấp.
- Toàn bộ change set NaBi Green Wellness UI.
- Checklist, kế hoạch, audit JSON, changed-file manifest, validation report, completion report và worklog.
- Test contract và static validation tool mới.

## Dữ liệu bị loại khỏi ZIP bàn giao

- `.env` và mọi file cấu hình bí mật cục bộ.
- Cache/build/generated state: `.dart_tool`, `.gradle`, `.kotlin`, `build`, platform `ephemeral`, `__pycache__`, `.pyc`.
- IDE/machine state: `.idea`, `.temp`, `.run`, `android/local.properties`, `.flutter-plugins-dependencies`.
- Các file `*.log`.

## Giới hạn nguồn đầu vào

Archive `nano_app(2).rar` không chứa thư mục root `assets/`, mặc dù `pubspec.yaml` khai báo 57 asset paths. Gói bàn giao không tạo asset giả và do đó vẫn cần ghép lại với asset tree chính xác từ repository gốc trước khi chạy Flutter analyze/test/build hoặc nghiệm thu visual.
