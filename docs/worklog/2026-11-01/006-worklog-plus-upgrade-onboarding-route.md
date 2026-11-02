Commit de xuat: docs(worklog): ghi nhan loi dieu huong nang cap Plus

# Worklog - Sửa điều hướng nâng cấp Plus

## Thời gian

- Ngày: 2026-11-01
- Bắt đầu: 22:30
- Kết thúc: 22:47
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: bugfix
- Module chính: V2 auth route guard / membership payment
- Yêu cầu gốc: Không chuyển sang onboarding khi người dùng đã đăng nhập chọn nâng cấp Plus.

## Đã làm

- Xác nhận `/v2/payments` bị guard chung đưa `onboardingRequired` về AuthGate; AuthGate điều hướng trạng thái đó tới onboarding.
- Nối router với chính sách cho phép thành viên đã đăng nhập và đang onboarding mở trang thanh toán.
- Giữ nguyên chặn khách, trạng thái auth chưa xác định, trạng thái đồng bộ chưa sẵn sàng và các route bảo vệ khác.
- Bổ sung test backend status `pending` và test đích redirect thực tế qua helper được router sử dụng.
- Giữ nguyên các thay đổi bẩn đã có trong checkout, gồm thay đổi AI/schedule và resolver `pending`.

## File code/docs đã sửa

- `lib/app_versions/v2/router/v2_router.dart` - dùng policy redirect có ngoại lệ riêng cho trang thanh toán.
- `test/app_versions/v2/router/v2_composed_route_guard_test.dart` - kiểm tra redirect cho payment, guest, auth pending và route bảo vệ khác.
- `test/app_versions/v2/features/auth/auth_route_state_resolver_test.dart` - bao gồm trạng thái backend `pending`.
- `docs/fixbug/plus-upgrade-onboarding-route/001-fixbug-plus-upgrade-onboarding-route.md` - ghi nguyên nhân và kết quả.

## Commands

- `dart format lib/app_versions/v2/router/v2_router.dart test/app_versions/v2/router/v2_composed_route_guard_test.dart test/app_versions/v2/features/auth/auth_route_state_resolver_test.dart`: PASS, không cần định dạng lại.
- `LD_LIBRARY_PATH=/tmp/nabi-sqlite-ffi flutter test --reporter=compact test/app_versions/v2/router/v2_composed_route_guard_test.dart test/app_versions/v2/features/auth/auth_route_state_resolver_test.dart`: PASS, 16 tests.
- `flutter analyze lib/app_versions/v2/router/v2_router.dart test/app_versions/v2/router/v2_composed_route_guard_test.dart test/app_versions/v2/features/auth/auth_route_state_resolver_test.dart`: PASS, không có issue.
- Dart MCP hot reload trên app đang chạy: PASS.
- Dart MCP runtime errors: không có lỗi.
- Kiểm tra UI điện thoại: SKIPPED cho CTA Plus; app hiện ở onboarding bước 8/9 và hoàn tất onboarding sẽ ghi dữ liệu ngoài phạm vi route check. Không thực hiện giao dịch.

## Lỗi/Rủi ro

- Đã fix: route thanh toán dùng policy đã định nghĩa và được kiểm thử; không còn redirect trạng thái `onboardingRequired` đã đăng nhập về onboarding khi mở payment route.
- Chưa fix: không phát sinh lỗi liên quan khác trong phạm vi.
- Cần kiểm tra tiếp: trên thiết bị, chọn CTA “Nâng cấp Plus” và xác nhận trang gói đăng ký mở mà không mua. Chưa thể đi tới CTA từ màn hình hiện tại mà không hoàn tất onboarding.

## Tỷ lệ hoàn thành

- Hoàn thành: source, regression tests, analyzer, hot reload.
- Đang dở: thao tác CTA Plus trực tiếp trên thiết bị chưa được kiểm chứng.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - lỗi redirect đã được nối với helper có test, thay vì chỉ kiểm thử helper không được router gọi.
- Mức độ hoàn thành task: source fix và kiểm thử tự động hoàn tất; xác minh thiết bị còn thiếu.
- Bằng chứng kiểm chứng: 16/16 tests, analyzer sạch, hot reload thành công, runtime không có lỗi.
- Điểm tốn token/chưa tối ưu: không thể mở CTA từ UI hiện tại mà không gửi lại form onboarding.
- Cách tối ưu cho phiên sau: dùng test router với trạng thái auth/sync giả lập để chứng minh redirect toàn vòng mà không ghi dữ liệu người dùng.
- Task-skill cần đọc lần sau: `.codex/task-skills/bugfix.md`
