Commit de xuat: fix(app): uu tien Admin va harden AI, notification

# Fixbug - Admin, AI chat/lịch cá nhân và notification reliability

## Hiện tượng

- Admin có thể đi vào user/onboarding trong lúc session hoặc quyền đang resolve.
- Sau login, Settings vẫn giữ card mời đăng nhập.
- Chat AI có thể báo lỗi chung hoặc giữ turn nội bộ dù quota commit thất bại; lịch fallback không cho biết nguồn và có nguy cơ bị trừ lượt như AI thật.
- Notification có thể còn pending của subject cũ, bị bấm sau khi đổi tài khoản, thiếu iOS background callback hoặc lỗi deep-link V3.

## Nguyên nhân

- Surface mặc định là user và auth provider đọc lại singleton thay vì dùng identity của event.
- Chat accept context trước lúc trusted quota commit xong; UI/controller gom một số lỗi thành unavailable.
- Lịch không mang provenance xuyên qua persistence; notification refresh không chọn một active subject duy nhất.
- Bootstrap notification có thể initialize song song; iOS và standalone V3 thiếu phần native/route cần thiết.

## Cách sửa

- Dùng `AppSurface.automatic`, ưu tiên Admin đã được xác thực; chỉ dual-role đã chủ động chọn mới vào user surface.
- Dùng `Stream<String?>` session identity cho auth/UI để card Settings phản ứng ngay.
- Tách `AIChatPreparedResponse`: response chỉ nhớ turn sau quota commit thành công. Chat fail-closed và đưa lỗi typed ra UI.
- Lưu `PlanGenerationSource` trong request ledger SQLite v16. Local fallback trở thành “lịch gợi ý cơ bản”, không commit quota member; schedule đã lưu vẫn giữ khi scheduling notification lỗi.
- Scheduler dọn OS/pending notifications theo active subject, stale source và account switch; nếu OS cancel lỗi thì giữ row để retry; action handler reject subject không active.
- Hoàn thiện iOS registrant/delegate, action “Mở nhiệm vụ + Để sau”, legacy `done` mở task, và route V1 lifestyle schedule trong V3 standalone.

## Kiểm chứng

- `flutter analyze`: PASS.
- Auth/Admin/Settings/router: 10 tests PASS.
- Notification: 44 tests PASS, gồm iOS static callback, cleanup subject/stale source, retry khi OS cancel lỗi, User A → User B và legacy done.
- AI/quota/migration: 81 tests PASS, gồm quota commit fail-closed, fallback không trừ lượt và SQLite provenance.
- Gemini REST/chat: 6 tests PASS, gồm prepared turn không vào history trước acknowledgement.
- Android `12b304f9`: debug build/install/bootstrap PASS; manual account và permission acceptance vẫn pending.

## Blocker live không che giấu

- Gemini preflight trả HTTP 401 cho toàn bộ model với credential local hiện tại. Đây là lỗi credential server-side; code đã map thành thông báo cấu hình/xác thực an toàn nhưng không thể tạo câu trả lời AI thật cho đến khi thay key Gemini hợp lệ.
- Supabase CLI và disposable sandbox project không có trong workspace, nên chưa chạy RPC quota/RLS acceptance; không chạy `docs/supabase/config.sql` trên production.
- Android physical device được nhận diện nhưng thiếu test account/credential hợp lệ để hoàn tất manual Admin/login/chat/schedule smoke. iOS device chưa có.
