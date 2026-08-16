# Fixbug - Lifestyle Schedule camera completion

## Phạm vi

- Module: M03 Lifestyle Schedule.
- Lỗi: nhiệm vụ đang ở trạng thái `Đang đến giờ` nhưng bấm nút hoàn thành không chuyển sang camera hoặc không có phản hồi khi quyền camera bị từ chối.

## Root cause

1. `LifestyleScheduleController.toggleItem()` gọi `beginCompletion()` của hệ Điểm chăm sóc trước khi mở camera. Lỗi eligibility/network/reward có thể chặn toàn bộ luồng người dùng.
2. `ImagePickerService.pickFromCamera()` trả `null` khi quyền camera bị từ chối. `null` cũng là giá trị dùng cho trường hợp người dùng chủ động hủy camera, nên UI không thể phân biệt và không hiển thị lỗi.

## Cách sửa

- Khi task đang trong cửa sổ hoàn thành, camera là hành động đầu tiên sau tap.
- Chỉ sau khi chụp và lưu proof hợp lệ mới reconcile eligibility/begin reward attempt.
- Lỗi reward có `canContinueWithoutReward=true` không chặn completion local.
- Lỗi reward hard-block vẫn không cộng điểm và proof vừa chụp được dọn để không tạo orphan.
- Riêng luồng proof dùng `pickFromCameraWithPermissionFeedback()`: permission denied/permanently denied phát sinh `ImagePickerServiceException` có message tiếng Việt; các caller camera cũ vẫn giữ contract `null` để tránh regression ngoài scope.
- Giữ single-flight `_busyItemIds` để chống double tap.
- Không cộng Điểm chăm sóc ở client; điểm chỉ được xác nhận từ `finalize_my_schedule_completion`.

## Regression coverage

- Tap đúng giờ mở camera.
- Camera cancel không hoàn thành task.
- Camera permission denied có feedback.
- Reward network lỗi vẫn hoàn thành local.
- Hard reward rejection xảy ra sau camera nhưng không commit task.
- Double tap chỉ chạy một completion flow.
- Member online upload/finalize và nhận `pointsDelta` từ server.
