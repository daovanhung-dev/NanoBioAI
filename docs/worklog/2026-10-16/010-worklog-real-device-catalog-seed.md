Commit de xuat: test(ai): verify real-device 3000 meal catalog seed

# Worklog - Xiaomi runtime seed verification

## Thời gian

- Ngày: 2026-10-16
- Timezone: Asia/Ho_Chi_Minh
- Tiếp tục mục tiêu chạy app, onboarding và tạo lịch AI trên thiết bị thật.

## Phạm vi

- Loại task: test/runtime verification.
- Module: M01 onboarding, M02 personal schedule AI, SQLite catalog.
- Mục tiêu phiên này: đồng bộ source hiện tại lên phiên `flutter run` đang hoạt
  động trên Xiaomi, chạy migration/seed v36, xác định onboarding/request state.
- Người dùng đã chỉ thị dùng AI thật với profile cá nhân và danh mục món/bài tập.
- Không in ra giá trị sức khỏe, tên người dùng, ID, raw prompt hoặc response.

## Đã làm

- Xác nhận thiết bị USB Xiaomi 220333QPG, Android 11/API 30. App
  `com.nanobioai.app` là debuggable; đã có phiên `flutter run` từ workspace
  hiện tại. Gắn vào phiên bằng `flutter attach --device-id 12b304f9
  --app-id com.nanobioai.app --no-dds`, để Flutter đồng bộ source/assets và
  gửi hot restart (`R`). App restart trong 6.648 ms.
- Database trên thiết bị trước restart là SQLite v35 với 163 món/40 bài tập.
  Sau restart là v36 với 3.163 món (3.000 candidate + 163 legacy) và 40 bài
  tập. Các số lượng profile/goals/condition/lifestyle/survey trước và sau
  không đổi.
- Trạng thái onboarding hiện có là `in_progress`; một request
  `initial_guest` trước đó là `failed`, chưa commit bữa/hoạt động nào và staging
  dùng prompt v10. Không tạo lại/xóa profile và không gửi request AI mới.
- Tài liệu bằng chứng: `docs/test/real-device-3000-meal-onboarding-2026-10-16/README.md`.

## Bằng chứng và lệnh

- `flutter devices --machine`: nhận Xiaomi serial `12b304f9`, model 220333QPG,
  Android 11/API 30.
- `flutter attach --device-id 12b304f9 --app-id com.nanobioai.app --no-dds`:
  kết nối được, đồng bộ files/assets.
- Flutter attach console `R`: `Restarted application in 6,648ms`.
- On-device read-only SQLite count query trước/sau restart: v35/163/40 đổi
  thành v36/3.163/40; `health_profiles`, `health_goals`, `health_conditions`,
  `lifestyle_habits` và `survey_answers` giữ nguyên số hàng.
- Current user state query: `onboarding_status=in_progress`; prior
  `initial_guest` status `failed`, `meal_count=0`, `exercise_count=0`; prior
  staging prompt version v10.
- CUA inventory trả `apps=[]`; `cua.listWindows` không có trong runtime API.
  Đã bật `scrcpy` nhưng UI native không được CUA expose. Không dùng adb input,
  UI hierarchy dump, hay test automation thay thao tác trực tiếp.
- Chưa gọi Gemini, chưa submit thông tin sức khỏe tới Edge Function, chưa có
  quota/billing response, chưa hoàn thành onboarding và chưa có lịch được commit.

## Kết quả và việc còn lại

- Đạt: app chạy trên thiết bị thật, source/assets được sync qua Flutter attach,
  migration/seed v36 và bảo toàn các hàng profile hiện có được xác nhận.
- Chưa đạt: hoàn thành onboarding và tạo lịch 7 ngày qua UI app; cần CUA có
  bề mặt điều khiển Android hoặc người dùng thao tác phần onboarding còn lại.
- Khi UI truy cập được, dùng profile đang lưu (không nhập dữ liệu giả), gửi một
  request qua luồng chuẩn `nabi-ai-generate` -> Gemini, rồi xác minh 35 bữa và
  14 hoạt động cùng response/quota thật.
- Không xác nhận quyền sử dụng/dữ liệu chuyên môn cho candidate; chúng chỉ
  được dùng trong policy wellness theo chỉ thị hiện tại.

## Tự đánh giá

- Chất lượng đầu ra: xác minh được seed và giữ dữ liệu thật, không lộ giá trị
  sức khỏe trong báo cáo.
- Mức độ hoàn thành: tiến triển thật trên thiết bị; end-to-end goal còn mở do
  thiếu Android UI interaction surface.
- Bằng chứng: Flutter attach/hot restart và SQLite v36/counts trên thiết bị.
- Hạn chế: CUA không có native app/window API trong phiên này, nên không thể
  hoàn tất thao tác UI hoặc AI call.
- Cách tối ưu phiên sau: khởi tạo CUA với một cửa sổ Android/scrcpy được expose
  trước khi tiếp tục; bắt đầu từ onboarding đang `in_progress`.
- Task-skill: `.codex/task-skills/test.md`.
