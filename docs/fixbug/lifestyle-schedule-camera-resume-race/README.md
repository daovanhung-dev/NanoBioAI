# Fixbug - Lifestyle Schedule camera resume race

## Hiện tượng

Sau khi người dùng chụp ảnh minh chứng và quay lại `Lịch trình cá nhân`, giao diện có thể vẫn hiển thị `0/N` nhiệm vụ đã hoàn thành. Nếu thao tác lại, ứng dụng hiển thị `Nhiệm vụ này đã được hoàn thành rồi.` dù timeline chưa phản ánh trạng thái hoàn thành.

## Root cause

System camera làm ứng dụng chuyển lifecycle và phát `AppLifecycleState.resumed` khi trả ảnh về. `LifestyleSchedulePage` trước đây gọi `refresh()` và `reconcilePendingRewards()` ngay tại `resumed`, trong khi `LifestyleScheduleController.toggleItem()` vẫn đang giữ completion flow active.

Hai flow có thể chạy song song:

1. lifecycle refresh đọc snapshot SQLite trước khi completion transaction commit;
2. completion transaction commit item thành completed;
3. refresh cũ ghi đè Riverpod state bằng snapshot pending;
4. lần tap kế tiếp dùng UI pending nhưng SQLite đã completed và datasource ném `alreadyCompleted`.

## Fix

- Expose `LifestyleScheduleController.hasActiveCompletionFlow`.
- `LifestyleSchedulePage.didChangeAppLifecycleState()` bỏ qua refresh/reconcile khi camera/completion còn active.
- `LifestyleScheduleController.refresh()` và `reconcilePendingRewards()` tự guard khi completion đang active để tránh caller khác tạo race tương tự.
- Sau `updateItemCompletion()`, controller reload `getWeekSchedule()` và `getCompletionProofs()` từ local repository thay vì sửa snapshot pre-camera trong memory.
- `ScheduleCompletionErrorCode.alreadyCompleted` khi đang complete được coi là idempotent success:
  - xóa ảnh mới chụp nhưng chưa được DB nhận để tránh orphan;
  - reload SQLite authoritative state;
  - không hiển thị error banner.

## Expected result

Sau khi chụp ảnh thành công:

- task hiển thị completed;
- tiến độ cập nhật ngay (`0/11 -> 1/11` trong trường hợp có 11 nhiệm vụ);
- proof đã lưu vẫn còn;
- không xuất hiện banner `Nhiệm vụ này đã được hoàn thành rồi.` do stale UI;
- reward flow Supabase tiếp tục dùng idempotency/finalize hiện có, không cộng điểm phía client.
