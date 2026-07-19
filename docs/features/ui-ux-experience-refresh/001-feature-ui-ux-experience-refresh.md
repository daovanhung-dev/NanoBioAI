Commit de xuat: feat(ui): dong bo clinical calm va nang cap trai nghiem toan bo NanoBio

# Feature - UI/UX Experience Refresh toàn dự án

## Mục tiêu

Chuẩn hóa toàn bộ lớp hiển thị NanoBio theo style **Clinical Calm × Nabi Friendly**: gọn, cân đối, dễ đọc, có phản hồi tương tác rõ và giữ nguyên toàn bộ business logic, kiến trúc, dữ liệu, quyền truy cập và luồng đồng bộ hiện có.

## Phạm vi

- V1 Guest/Basic: Splash, Onboarding, Dashboard, Menu/Features Hub, lịch trình, dinh dưỡng, theo dõi sức khỏe, hồ sơ, cài đặt và Nabi.
- V2 Authenticated/Free: Auth, Home, Health Score, Health Module access, Wellness Rewards, Payment/Sale entry.
- V3 Plus/FamilyPlus: Advanced Tracking, FamilyPlus và các surface trả phí hiện có.
- Admin: shell, section navigation và các component dùng ThemeData chung.
- Sale/referral: participation và shell được điều hướng qua route stack có thể quay lại.
- Shared presentation/theme primitives dùng xuyên dự án.

Không bao gồm `dev_database_viewer_page.dart`, `design_system_demo_page.dart`, controller, provider, repository, datasource, DAO, model, SQLite, Supabase, RPC hoặc thay đổi route catalog.

## Style chốt

### Clinical Calm

- Medical blue là màu hành động chính; wellness teal dùng cho trạng thái tích cực.
- Nền xanh xám rất nhẹ, card sạch, viền mảnh, ít shadow.
- Typography phân cấp rõ; giảm cỡ và mật độ ở thành phần phụ.
- Component compact nhưng vẫn giữ vùng chạm tối thiểu 44–48 px.
- Spacing theo lưới 4/8 px và token hiện có; radius giảm nhẹ để giao diện gọn hơn.

### Nabi Friendly

- Chỉ giữ copy cần thiết, rõ và không phán xét.
- Nabi là điểm nhấn cảm xúc, không lấn át thông tin sức khỏe.
- Hiệu ứng nhẹ, mềm, có mục đích và tự tắt khi hệ điều hành yêu cầu giảm chuyển động.

## Thay đổi nền tảng

- Bổ sung `AppPageTransitionsBuilder` cho fade/slide/scale thống nhất trên Android, iOS, desktop và Fuchsia.
- Bổ sung `AppViewMotion` cho section reveal và stagger animation.
- Bổ sung `AppPressScale` cho phản hồi nhấn trên button/card tương tác.
- Chuẩn hóa ThemeData: density, AppBar, input, button, icon button, navigation bar, spacing, radius và animation duration.
- `AppExperience` bổ sung tap-outside để đóng bàn phím, giữ focus traversal và scroll behavior dùng chung.
- `MedicalPageScaffold`, `MedicalScrollPage`, `MedicalSurfaceCard` và primitive button/card được nâng cấp tại một điểm để phủ nhiều view mà không lặp code.

## Back-navigation

- Các thao tác mở view chi tiết dùng `push` thay vì `go` để bảo toàn history stack.
- Route chuyển tiếp sau xác thực, đăng xuất, splash và hoàn tất onboarding tiếp tục dùng replacement/root navigation đúng bản chất.
- Onboarding dùng nút Back của điện thoại để quay từng bước; ở bước đầu quay về view mở onboarding.
- Health module gate và Sale activation dùng `pushReplacement` để thay gate bằng destination nhưng vẫn giữ view trước gate.
- Nabi global mở AI Chat bằng `push`, tránh làm mất view nguồn.

## Onboarding

- Rút gọn tiêu đề, mô tả và hướng dẫn lặp ở entry cùng 9 bước hiện có trong source.
- Giữ nguyên field, lựa chọn sức khỏe, validation, consent, cảnh báo y tế và CTA có contract test.
- Số từ trong string literal thuộc phạm vi onboarding presentation giảm khoảng 22,6%; phần giảm tập trung vào mô tả hỗ trợ, không cắt dữ liệu bắt buộc.

## Invariants được giữ

- Không thay đổi số bước onboarding hoặc controller state.
- Không thay đổi điều kiện hoàn tất onboarding, AI plan, quota hoặc request ledger.
- Không thay đổi auth, membership, payment, Sale, Admin permission hoặc cloud sync.
- Không thêm mock/sample data production.
- Không đọc, ghi hoặc đóng gói `.env`, auth env, token hay dữ liệu sức khỏe nhạy cảm.

## Tiêu chí nghiệm thu

- Mọi app surface production dùng chung `AppTheme` và `AppExperience`.
- Route transition, press feedback và reduced-motion behavior thống nhất.
- View mở từ view khác giữ được history để hardware Back quay lại.
- Onboarding ngắn gọn hơn nhưng không mất nội dung bắt buộc.
- Toàn bộ file thay đổi nằm trong `presentation` hoặc `core/theme`.
- Static source validation và import resolution đạt; compile/analyze/test runtime phải chạy lại trên máy có Flutter SDK.
