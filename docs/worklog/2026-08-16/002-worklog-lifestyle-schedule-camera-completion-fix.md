# Worklog - Fix nút hoàn thành lịch trình không mở camera

## Loại task

- Workflow: `bugfix`
- Domain: `lifestyle-schedule`
- Module: M03 Lifestyle Schedule

## Vấn đề

Ảnh runtime cho thấy task `12:30` hiển thị `Đang đến giờ` nhưng nút hoàn thành không chuyển sang giao diện camera.

## Phân tích

- `ScheduleTimeline` và `ScheduleItemCard` đã cho phép tap khi `isWithinCompletionWindow(now)` là `true`.
- Blocker nằm trong controller: reward `beginCompletion()` chạy trước camera và có thể return `blocked`.
- Camera permission denied đang trả `null`, trùng với semantic của thao tác cancel và tạo silent failure.

## Thay đổi

- `lifestyle_schedule_controller.dart`
  - camera chạy ngay sau validation cửa sổ thời gian;
  - reward eligibility/begin chạy sau capture;
  - fallback local-only cho lỗi reward có thể tiếp tục;
  - hard reward error dọn proof và không commit task;
  - hiển thị typed camera permission error;
  - giữ Supabase finalize là nguồn chuẩn của điểm.
- `image_picker_service.dart`
  - bổ sung dependency injection cho permission request để test được;
  - giữ nguyên `pickFromCamera()` cho các caller cũ;
  - thêm `pickFromCameraWithPermissionFeedback()` cho proof flow;
  - permanently denied hướng dẫn mở Settings.
- `schedule_proof_image_service.dart`
  - opt-in camera permission feedback cho riêng luồng ảnh minh chứng.
- Regression tests cho controller, image picker permission, proof service và UI tap target.

## Validation

Môi trường artifact không có Flutter/Dart SDK và không clone được GitHub qua DNS, nên chưa chạy được `dart format`, `flutter analyze`, `flutter test` trong phiên này. Đã thực hiện static checks trên các file đóng gói: cấu trúc delimiter, không còn `remoteAttempt!`, không có client-side point increment, camera call đứng trước `beginCompletion`, và ZIP integrity.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tốt - fix bám đúng root cause runtime và không mở rộng policy thời gian.
- Muc do hoan thanh task: code + regression tests + package hoàn tất; runtime Flutter chưa xác minh trong môi trường hiện tại.
- Bang chung kiem chung: source `main` qua GitHub connector, static checks và kiểm tra ZIP.
- Diem ton token/chua toi uu: GitHub code search không index tốt nên phải fetch file theo path.
- Cach toi uu cho phien sau: chạy targeted Flutter tests trên checkout/local runner có SDK trước khi build APK.
- Task-skill can doc lan sau: `.codex/task-skills/bugfix.md`
