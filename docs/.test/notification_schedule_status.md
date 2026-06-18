# Báo cáo kiểm thử thông báo lịch trình

Ngày lập báo cáo theo session Codex: 2026-06-18.
Thiết bị Android kiểm tra qua ADB báo ngày: 2026-06-19.

## Kết luận ngắn

Chức năng thông báo lịch trình đã hoàn thành ở mức code, automated test và xác minh lịch hẹn trên thiết bị. Luồng hiện có đọc dữ liệu từ bảng `lifestyle_schedule_items`, tạo notification có nội dung từ nhiệm vụ, có nút `Đã làm`, và logic action `done` cập nhật SQLite.

Chưa nên kết luận hoàn thành 100% production vì chưa xác minh bằng thao tác thực tế trên thanh thông báo đúng thời điểm: chờ notification hiện ra, bấm `Đã làm`, sau đó đọc lại DB trên máy thật để thấy row đổi trạng thái. Phần còn lại là device/manual verification, không phải thiếu luồng code chính.

## Trạng thái theo yêu cầu

1. Lên lịch thông báo dựa vào bảng `lifestyle_schedule_items`: ĐẠT

- `ReminderScheduleService.scheduleGeneratedReminders()` đọc `scheduleItemsDao.getAll()`, lọc item chưa hoàn thành và có thời gian tương lai.
- Trên thiết bị `220333QPG`, DB `bioai.db` có:
  - `lifestyle_schedule_items`: 70 row.
  - `lifestyle_schedule_items` tương lai chưa hoàn thành: 70 row.
  - `notifications`: 70 row.
  - `notifications` pending với `source_type = lifestyle_schedule_item`: 70 row.
- Cache plugin `scheduled_notifications.xml` có 70 scheduled notifications, tất cả có occurrence `lifestyle_schedule_item`.
- `dumpsys alarm` có 70 alarm `RTC_WAKEUP` của `com.example.nano_app` trỏ tới `ScheduledNotificationReceiver`.

2. Đến giờ đã lên lịch thì hiện notification trên thanh thông báo: GẦN ĐẠT, CẦN XÁC MINH BẰNG MẮT

- Code dùng `flutter_local_notifications.zonedSchedule()` với timezone `Asia/Ho_Chi_Minh`.
- Cache trên thiết bị cho thấy schedule mode là `exactAllowWhileIdle` cho 70 notification.
- Manifest Android đã khai báo `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `SCHEDULE_EXACT_ALARM`, `ScheduledNotificationReceiver`, `ScheduledNotificationBootReceiver`, và `ActionBroadcastReceiver`.
- Mẫu dữ liệu trên thiết bị:
  - `2026-06-20T06:00:00` - `Thức dậy`
  - `2026-06-20T06:15:00` - `Uống nước đầu ngày`
  - `2026-06-20T07:00:00` - `Ăn sáng: Cháo đậu xanh bí đỏ`
- Chưa có bước chờ tới đúng giờ và quan sát notification trên thanh thông báo trong phiên này.

3. Notification có nút `Đã làm`, bấm nút thì cập nhật SQLite: ĐẠT Ở MỨC LOGIC/AUTOMATED TEST, CHƯA XÁC MINH BẰNG BẤM THẬT

- Notification Android khai báo action:
  - `done` với label `Đã làm`.
  - `skipped` với label `Chưa làm`.
- `NotificationActionHandler.handleAction()` xử lý action `done`, cập nhật notification thành `action_status = done`, `is_read = 1`, sau đó gọi cập nhật source.
- Nếu source là `lifestyle_schedule_item`, handler gọi `LifestyleScheduleLocalDatasource.updateItemCompletion()`.
- Datasource cập nhật item thành `is_completed = true`, `current_value = target_value`, đồng bộ linked meal/daily task nếu có và cập nhật daily score.
- Automated test `done schedule item completes timeline item and linked meal` đã pass, xác nhận row schedule và linked meal được đánh dấu hoàn thành trong SQLite in-memory.
- Chưa có bước bấm nút `Đã làm` trên notification thật và đọc lại DB device ngay sau thao tác.

## Bằng chứng code

- `lib/services/notifications/reminder_schedule_service.dart`: đọc `lifestyle_schedule_items`, tạo candidate từ `schedule_date` + `start_time`, tạo payload/id ổn định và insert row notification.
- `lib/services/notifications/reminder_notification_scheduler.dart`: init local notification, xin quyền, đặt `zonedSchedule`, gắn action `Đã làm` và `Chưa làm`.
- `lib/services/notifications/notification_bootstrap.dart`: init timezone, init scheduler, nối callback foreground/background về action handler.
- `lib/services/notifications/notification_action_handler.dart`: parse payload, update `notifications.action_status`, và cập nhật source tương ứng.
- `lib/features/lifestyle_schedule/data/datasources/lifestyle_schedule_local_datasource.dart`: update completion cho item và đồng bộ các bảng liên quan.
- `android/app/src/main/AndroidManifest.xml`: có các permission/receiver cần thiết cho local notification và action.

## Lệnh đã chạy

- `flutter test test\services\notifications`: PASS, 15/15 tests.
- `flutter analyze`: FAIL, 319 issues. Các issue là warning/info/lint tổng thể repo hiện hữu như unused helper, deprecated `withOpacity`, sort/format lint, `avoid_print` trong test. Không thấy lỗi compile riêng làm đứt luồng notification.
- `flutter devices`: PASS, thấy thiết bị Android `220333QPG` Android 11/API 30.
- `adb -s 12b304f9 shell pm list packages com.example.nano_app`: PASS, app đã cài trên device.
- `adb -s 12b304f9 shell run-as com.example.nano_app ...`: PASS, đọc được data debug của app.
- `sqlite3` trên bản copy tạm của `bioai.db`: PASS, `PRAGMA integrity_check` trả `ok`.
- `adb -s 12b304f9 shell dumpsys alarm | findstr ...`: PASS, thấy 70 alarm của app trỏ tới `ScheduledNotificationReceiver`.

## Mức độ hoàn thành hiện tại

Mức độ hiện tại: gần hoàn thành. Có thể xem là đã xong phần code và automated validation, đồng thời đã có bằng chứng trên device rằng 70 lịch notification đã được Android AlarmManager nhận.

Còn thiếu duy nhất để đóng dấu production là manual/device acceptance:

- Chờ tới một mốc schedule gần nhất hoặc tạo dữ liệu test có `start_time` gần hiện tại.
- Mở app để refresh scheduler nếu cần.
- Xác nhận notification thật sự hiện trên thanh thông báo với title/body đúng nhiệm vụ.
- Bấm `Đã làm`.
- Đọc lại DB device và xác nhận:
  - `lifestyle_schedule_items.is_completed = 1`.
  - `lifestyle_schedule_items.current_value = target_value`.
  - `notifications.action_status = done`.
  - `notifications.is_read = 1`.

## Nhận xét rủi ro

- Trên Android 11 không có runtime permission `POST_NOTIFICATIONS` như Android 13+, nhưng exact alarm vẫn phụ thuộc quyền/chế độ pin của máy. Cache hiện tại đang dùng `exactAllowWhileIdle`.
- Nếu app bị force-stop, alarm của app có thể bị Android hủy cho đến khi user mở lại app.
- Nếu action background bị OS kill trong điều kiện tiết kiệm pin mạnh, cần test thêm trên máy thật sau khi app bị đưa về background lâu.
- Repo hiện fail `flutter analyze` do nợ kỹ thuật có sẵn, nên Definition of Done toàn repo chưa sạch. Riêng notification tests đang xanh.
