# Khôi phục trang chủ khi đồng bộ hồ sơ cloud lỗi

## Hiện tượng

Dashboard trên Xiaomi không tải được vì SQLite v26 toàn vẹn nhưng chưa có hàng
`users` hoặc `health_profiles`. Phiên đăng nhập vẫn còn và cờ cloud pull đang
chờ. Nút **Thử lại** trước đây chỉ tải lại dashboard local, không đọc cờ đồng bộ
đã lưu và không gọi cloud sync.

## Nguyên nhân

`DashboardLocalDatasource.fetchDashboard()` yêu cầu hồ sơ local theo UID đăng
nhập. Khi cloud pull trước đó lỗi, `DashboardPage` vẫn vào được trạng thái lỗi
dashboard, nhưng callback retry chỉ invalidate `dashboardProvider` và
`dashboardDynamicProvider`. Vì không có hồ sơ trong SQLite, lần đọc tiếp theo
lại lỗi ngay.

Staging trả `404 PGRST205` cho `public.fitness_training_programs`, dù cùng phiên
QA đọc được hàng `users` và `health_profiles`. Remote datasource hỏi mọi bảng
tuần tự; lỗi ở bảng này làm hủy toàn bộ snapshot trước khi ghi hồ sơ local.

## Sửa

- Nút **Thử lại** làm mới trạng thái outbox và cờ cloud pull bằng
  `UserDataSyncController.refreshLocalStatus()`.
- Nếu pull hoặc upload còn pending, gọi `UserDataSyncController.retry()` hiện có
  rồi tải lại dashboard và dữ liệu động. Bước kiểm tra vẫn chạy khi state trong
  bộ nhớ đang `syncing`; repository coalesce các yêu cầu sync đang chạy.
- Giữ `awaitingConsent` để không bỏ qua lựa chọn khôi phục đang chờ.
- Bỏ qua riêng `PGRST205` cho bảng phụ `fitness_training_programs` chưa được
  triển khai ở staging; các lỗi khác vẫn làm sync thất bại.
- Khi snapshot không có khóa của một bảng, giữ các rows local của bảng đó.
  Danh sách rỗng tường minh từ cloud vẫn xóa rows như trước.
- Khi sync lỗi, giữ nguyên phiên và dữ liệu local; hiện hướng dẫn kiểm tra kết
  nối và thử khôi phục lại. Không tạo hồ sơ giả hoặc xóa database.
- Bọc `ExpansionTile` mục tiêu sức khỏe bằng `Material` để loại bỏ Flutter
  assertion khi dashboard render thành công.

## Kiểm chứng

- Regression widget tests: cloud retry thành công làm dashboard hiện lại; retry
  thất bại giữ dữ liệu local và hướng dẫn khôi phục; trạng thái idle không gọi
  cloud retry. Ca thành công bắt đầu từ state `syncing` và cờ local pending.
- Remote datasource test xác nhận chỉ bỏ qua bảng optional khi nhận `PGRST205`.
- SQLite proof test xác nhận bảng bị lược khỏi snapshot giữ dữ liệu local, còn
  bảng có danh sách rỗng tường minh được xóa theo cloud.
- Focused Flutter suite: 17/17 PASS (dashboard, datasource, repository, SQLite
  replacement và remote datasource).
- `flutter analyze --no-pub`: không có vấn đề.
- APK debug staging build thành công và `adb install -r` thành công trên Xiaomi
  220333QPG / Android 11 (API 30); cài đè giữ dữ liệu.
- Sau build cuối, app tự đồng bộ thành công khi mở: SQLite v26,
  `integrity_check=ok`, `users=1`, `health_profiles=1`,
  `cloud_pull_retry_pending=false`; dashboard đã render đầy đủ. Logcat không có
  fatal exception, AndroidRuntime error hoặc Flutter error.
- Read-only QA request xác nhận chỉ hai hàng ID được nhìn thấy cho phiên đang
  đăng nhập; không xuất UID hoặc thông tin hồ sơ. Không ghi dữ liệu staging,
  chạy migration hoặc gọi Edge dispatch.

## Giới hạn

Bảng `fitness_training_programs` chưa có trong schema cache staging. Client giữ
rows local nếu có và khôi phục các bảng hồ sơ cần cho trang chủ; migration/schema
cloud không bị thay đổi trong lượt này.
