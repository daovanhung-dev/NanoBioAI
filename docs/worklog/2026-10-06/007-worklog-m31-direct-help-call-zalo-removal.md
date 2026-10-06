# Worklog — M31 gọi trực tiếp khi cần trợ giúp và gỡ Zalo

## Phạm vi

- Loại task: coding / Supabase schema / Android QA.
- Module: M31 `SLEEP_SAFETY_MONITORING`.
- Yêu cầu: cuộc gọi manual chạy từ thiết bị; tự động khi không phản hồi sau
  60 giây vẫn dùng voice/SMS; loại Zalo khỏi luồng hiện hành.

## Đã làm

- Thêm phone gateway cho Flutter; Android kiểm tra quyền `CALL_PHONE` và gọi
  bằng `ACTION_CALL`, iOS mở `tel:`. Nếu Android bị từ chối quyền hoặc không
  khởi tạo được, app mở trình gọi đã điền số để người dùng bấm Gọi.
- Khi bấm `Tôi cần hỗ trợ`, controller chọn contact active có bật phone opt-in
  với priority nhỏ nhất, lưu phản hồi cục bộ và không gọi server dispatch. Cờ
  tắt/thiếu contact/lỗi khởi tạo đều giữ alert và hiện hướng xử lý. Trạng thái
  chỉ nói OS khởi tạo hoặc app chuyển sang trình gọi, không nói cuộc gọi đã nối.
- Gỡ lựa chọn và field Zalo khỏi client, model, RPC, runtime config, Edge
  dispatch/provider callback và tài liệu hiện hành. Giữ nguyên migrations
  lịch sử 09:00/10:00/11:00; thêm Supabase forward migration 12:00 và SQLite v28
  để xóa opt-in cũ mà vẫn giữ contact/cache fields khác.
- Áp dụng migration 12:00 và deploy `sleep-safety-dispatch`,
  `sleep-safety-provider-webhook` chỉ trên QA
  `rnwohifdnylqfofkydfl`. Preflight thấy 1 contact có opt-in cũ, 0 dispatch Zalo
  lịch sử, cờ `phone_fallback_enabled=false`. Sau migration: vẫn 1 contact,
  không còn hai cột Zalo, còn đúng RPC 7 tham số hiện tại và không có dispatch
  Zalo. Không chạm production.
- Cờ gọi QA được bật tạm sau xác nhận giá trị ban đầu là `false`. APK debug được
  cài lên Xiaomi bằng `adb install -r`, giữ dữ liệu app hiện có.
- Người dùng xác nhận cuộc gọi QA trên Xiaomi đổ chuông và được bắt máy; contact
  QA tạm được xóa qua app. Cờ gọi QA được trả về `false`; read-only query xác
  nhận contact ban đầu vẫn còn đúng một bản ghi.

## Kiểm chứng

- Flutter focused controller/repository/model/SQLite v28/Supabase contract:
  **36/36 PASS** across controller, repository, model, UI recovery, phone
  contract, SQLite v26–v28, and Supabase contract tests.
- `flutter analyze`: **0 issues**.
- `flutter build apk --debug`: PASS.
- Deno dispatch/provider callback tests: **7/7 PASS**; `deno fmt --check` PASS.
- QA migration list 09:00–12:00, schema/RPC query, preserved-contact count,
  and both Edge Function deploy results: PASS.
- `git diff --check`: PASS.

## Nghiệm thu còn chờ

- Không có iPhone trong lượt này; iOS chỉ có source/test review.
- Xiaomi call acceptance đã qua một lần: user xác nhận đã đổ chuông và bắt máy.
  Đây không phải cam kết cuộc gọi nào cũng kết nối trong mọi điều kiện.

## Rủi ro được ghi nhận

- Không thể cam kết mọi cuộc gọi kết nối: còn tùy quyền hệ điều hành, SIM, mạng,
  nhà mạng và người nhận bắt máy.
- Không đọc/ghi số QA vào worklog, tài liệu hoặc test fixture.
