Commit de xuat: fix(schedule): them yeu cau AI tao lich khi con mot ngay

# Fixbug - Nút yêu cầu AI tạo lịch trình cá nhân tiếp theo

## Baseline

- Repository: `daovanhung-dev/NanoBioAI`
- Branch: `main`
- Baseline đọc khi phân tích: `8cdd1e15b10ab299ae58737948f67272a470e44b`
- Workflow: `bugfix`
- Module chính: Lifestyle Schedule / Personal Schedule AI

## Lỗi

Màn hình `LifestyleSchedulePage` hiển thị lịch cá nhân, tiến độ, Daily Health Hub,
timeline và ảnh minh chứng nhưng không có thao tác để người dùng chủ động yêu
cầu Nabi tạo lịch 7 ngày tiếp theo.

Runtime đã có sẵn luồng tạo lịch mới trong
`DashboardController.generateAdditionalPlan()` và `GeneratedPlanService`:

- yêu cầu tài khoản đăng nhập;
- đọc horizon lịch hiện tại;
- chặn khi lịch còn từ 2 ngày trở lên;
- kiểm tra Daily Routine Preferences;
- kiểm tra quota tạo lịch;
- tạo và append 7 ngày tiếp theo;
- refresh dashboard, lịch trình, thực đơn và nutrition.

Vì vậy root cause là thiếu entry point ở UI Lịch trình cá nhân, không phải thiếu
pipeline AI.

## Cách sửa

1. Thêm `scheduleHorizonProvider` trong provider của Lifestyle Schedule để UI
   đọc `ScheduleHorizon` qua abstraction `ScheduleHorizonReader`, không truy cập
   SQLite trực tiếp.
2. Thêm `ScheduleRegenerationCard` vào màn Lịch trình cá nhân.
3. Nút `Tạo lịch trình mới` chỉ enable khi:
   - `remainingDays < 2` (0 hoặc 1 ngày);
   - horizon đã load thành công;
   - không có lỗi horizon;
   - không có request generation đang chạy.
4. Trước khi submit, page kiểm tra lại `remainingDays < 2` để chống thao tác
   stale/race từ UI.
5. Gọi lại `DashboardController.generateAdditionalPlan()` hiện có thay vì tạo
   pipeline AI mới.
6. Khi thành công, invalidate horizon để card phản ánh ngay lịch 7 ngày mới.
7. Giữ nguyên xử lý auth, quota, Daily Routine Preferences, lỗi AI và nâng cấp
   Plus theo behavior Dashboard hiện tại.

## Hành vi sau sửa

### Lịch còn trên 1 ngày

- Card tạo lịch mới vẫn hiển thị để người dùng biết tính năng.
- Nút disabled.
- UI cho biết còn bao nhiêu ngày và mở nút khi lịch còn dưới 2 ngày.

### Lịch còn 0 hoặc 1 ngày

- Nút được enable.
- Người dùng có thể gửi yêu cầu tạo lịch 7 ngày tiếp theo.
- Trong lúc tạo, nút bị khóa và hiện `Nabi đang tạo lịch...`.

### Horizon chưa đọc được hoặc có lỗi

- Nút disabled vì chưa thể xác định số ngày còn lại an toàn.
- Người dùng được hướng dẫn kéo xuống để Nabi kiểm tra lại dữ liệu.

## File thay đổi

- `lib/app_versions/v1/features/lifestyle_schedule/presentation/pages/lifestyle_schedule_page.dart`
- `lib/app_versions/v1/features/lifestyle_schedule/presentation/widgets/schedule_regeneration_card.dart`
- `lib/app_versions/v1/features/lifestyle_schedule/providers/lifestyle_schedule_provider.dart`
- `test/features/lifestyle_schedule/presentation/schedule_regeneration_card_test.dart`

## Regression coverage

Widget test khóa các trường hợp:

- còn 2 ngày: disabled, callback không chạy;
- còn 1 ngày: enabled, callback chạy đúng một lần;
- còn 0 ngày: enabled, callback chạy đúng một lần;
- đang generation: disabled, chống double tap.

## Validation status

- Static guard `remainingDays < 2`: PASS.
- Không có SQLite/DAO import trực tiếp trong `LifestyleSchedulePage`: PASS.
- Dart/Flutter format/analyze/test: chưa chạy được trong môi trường đóng gói vì
  runtime hiện tại không có `dart`/`flutter` executable.
- Device test: UNVERIFIED.
- Không thay đổi SQLite schema hoặc Supabase schema/RPC.
