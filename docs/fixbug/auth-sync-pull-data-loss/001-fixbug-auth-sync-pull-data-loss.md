Commit de xuat: fix(sync): chan pull cloud ghi de local write chua push

# Fixbug - M05 có thể mất request ledger và local write chưa push

## Root cause

1. `personal_schedule_ai_requests` tồn tại trong SQLite/RPC nhưng bị thiếu trong danh sách snapshot/map/serialize chung, nên round-trip full snapshot có thể xóa hoặc bỏ sót request ledger.
2. Authenticated sync có thể pull cloud và replace cache trước khi outbox của đúng auth user được xác nhận đã push.
3. Ngay cả khi đã kiểm tra outbox trước pull, local write mới vẫn có thể xuất hiện trong lúc network pull đang chạy và bị replace cache ghi đè.
4. Guest merge trước đây chưa có consent state đủ rõ để phân biệt tài khoản cloud mới với tài khoản đã có dữ liệu.

## Cách sửa

- Khôi phục request ledger vào snapshot/local-cloud column map và serialize bằng `request_id`.
- Tách `genericIdUserOwnedTables` khỏi toàn bộ `userOwnedTables` để không sinh trigger dùng `id` cho bảng chỉ có `request_id`.
- Drain outbox theo đúng auth user trước pull. Nếu push lỗi hoặc còn marker, trả `pendingUpload`, giữ local/outbox và bỏ qua pull.
- `replaceFromCloud` chạy transaction và kiểm tra lại outbox ngay trước khi xóa/ghi cache. Nếu có marker mới, ném `LocalSyncPendingWriteException` và rollback toàn bộ replacement.
- Pull lỗi đặt durable retry marker; resume/connectivity/manual retry cùng đi qua single-flight coordinator.
- Guest consent được thực hiện trước mọi upload/xóa; defer không thay đổi dữ liệu.
- Sign-out preflight trả kết quả cho UI; force sign-out không xóa marker.

## Regression coverage đã thêm

- Request ledger nằm trong snapshot/map và không nằm trong generic-ID trigger list.
- Pending outbox không bao giờ được theo sau bởi pull.
- Outbox đã drain thì thứ tự là push trước pull.
- Local write xuất hiện trong lúc pull làm cache replacement bị từ chối.
- Guest upload/pull lỗi vẫn giữ Guest marker.
- Fresh-cloud merge, defer và established-cloud confirmation.

## Trạng thái kiểm chứng

- Static source/YAML/import/delimiter checks trong môi trường hiện tại: PASS.
- Flutter format/analyze/test/build: BLOCKED vì máy thực thi không có Flutter/Dart SDK.
- Supabase sandbox, RLS, atomic signup rollback và device `12b304f9`: BLOCKED vì không có quyền/kết nối môi trường tương ứng.
- Vì vậy fix đã có code + regression test source, nhưng production acceptance vẫn **PENDING**.
