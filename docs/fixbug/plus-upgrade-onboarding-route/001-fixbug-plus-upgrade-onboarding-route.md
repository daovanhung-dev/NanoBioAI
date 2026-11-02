Commit de xuat: fix(router): cho phep mo thanh toan khi onboarding pending

# Fix - Chọn nâng cấp Plus bị chuyển về onboarding

## Triệu chứng

Người dùng đã đăng nhập chọn “Nâng cấp Plus” nhưng ứng dụng chuyển sang onboarding thay vì mở trang gói đăng ký.

## Nguyên nhân

Backend trả `onboarding_status=pending`, được `AuthRouteStateResolver` phân loại là `onboardingRequired`. Router bảo vệ `/v2/payments` nhưng chỉ cho `authenticatedReady` đi tiếp; trạng thái onboarding-required bị chuyển qua AuthGate rồi tới onboarding. `V2RouteGuards.canAccessMembershipPayment` đã mô tả chính sách cho phép thành viên đã đăng nhập mở trang thanh toán trong trạng thái này, nhưng router chưa sử dụng chính sách đó.

## Thay đổi

- Router dùng một hàm quyết định đích redirect duy nhất cho các route cần xác thực.
- Trang thanh toán được mở khi người dùng đã đăng nhập và trạng thái là `onboardingRequired` hoặc `authenticatedReady`.
- Khách tiếp tục bị đưa tới đăng nhập; các route bảo vệ khác và trạng thái chưa xác minh tiếp tục qua AuthGate.
- Không thay đổi backend, trạng thái onboarding, hay xác minh giao dịch/quyền Plus.

## Kiểm chứng

- Test route guard và auth resolver: 16/16 đạt.
- `flutter analyze` trên ba file Dart liên quan: không có lỗi.
- Hot reload thành công; Dart runtime báo không có lỗi.
- Chưa xác minh CTA Plus trên điện thoại: thiết bị đang ở onboarding bước 8/9, và hoàn tất bước này sẽ ghi dữ liệu onboarding/lịch. Không thực hiện thao tác đó hoặc mua gói trong phiên xác minh.
