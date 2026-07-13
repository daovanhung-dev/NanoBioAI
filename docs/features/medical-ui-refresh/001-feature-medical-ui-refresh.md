Commit de xuat: feat(ui): nang cap toan bo giao dien theo he thong y te hien dai

# Feature - Medical UI Refresh

## Mục tiêu

Nâng cấp toàn bộ lớp trình bày NanoBio theo hướng y tế hiện đại, chuyên nghiệp, bình tĩnh và dễ sử dụng; giữ nguyên nghiệp vụ, provider, repository, datasource và hợp đồng đồng bộ hiện tại.

## Phạm vi triển khai

- Áp dụng một hệ thống theme Material 3 thống nhất cho V1, V2, V3, Sale và Admin.
- Thay bảng màu cũ bằng medical blue, wellness teal, clinical navy và các màu trạng thái có ngữ nghĩa.
- Chuẩn hóa typography, khoảng cách, bo góc, bóng đổ, input, button, card, navigation, dialog, bottom sheet, chip, picker và trạng thái focus.
- Tạo lớp `AppExperience` dùng chung để đồng nhất nền, điều hướng bàn phím và hành vi cuộn trên mobile/desktop.
- Tạo bộ primitive `MedicalPageScaffold`, `MedicalPageHero`, `MedicalSurfaceCard`, `MedicalSectionHeader`, `MedicalMetricCard`, `MedicalEmptyState` và `MedicalComingSoonPage`.
- Chuyển toàn bộ page production khỏi `Scaffold` trực tiếp sang `MedicalPageScaffold`; các màn onboarding/splash/loading vẫn giữ nền chuyên biệt bằng `ambientBackground: false`.
- Nâng cấp các view trọng tâm: đăng nhập/đăng ký, Dashboard, Features Hub, Settings, V2 Home, V3 Home và các trang trạng thái chưa phát hành.
- Giữ nguyên các luồng Auth V2, Supabase sync, membership, Sale và Admin.

## Nguyên tắc UX

1. Thông tin sức khỏe được chia theo mức ưu tiên rõ ràng, không nhồi dữ liệu.
2. Màu sắc dùng theo ý nghĩa; không dùng màu trang trí làm thay đổi nghĩa trạng thái.
3. Vùng chạm tối thiểu được nâng lên qua theme button/icon và `MaterialTapTargetSize.padded`.
4. Focus, hover, pressed và disabled có trạng thái nhìn thấy được.
5. Nội dung hỗ trợ dùng giọng Nabi nhẹ nhàng, không chẩn đoán và không gây lo lắng.
6. Các view co giãn cho điện thoại, tablet và desktop; form đăng nhập chuyển sang bố cục hai cột khi đủ rộng.

## File chính

- `lib/core/theme/app_colors.dart`
- `lib/core/theme/app_text_styles.dart`
- `lib/core/theme/app_theme.dart`
- `lib/core/theme/app_experience.dart`
- `lib/core/theme/medical_ui.dart`
- `lib/app_versions/v2/features/auth/presentation/pages/auth_pages.dart`
- `lib/app_versions/v1/features/dashboard/presentation/pages/dashboard_page.dart`
- `lib/app_versions/v1/features/features_hub/presentation/pages/features_hub_page.dart`
- `lib/app_versions/v1/features/settings/presentation/pages/settings_page.dart`
- `lib/app_versions/v2/features/home/presentation/pages/v2_home_page.dart`
- `lib/app_versions/v3/features/home/presentation/pages/v3_home_page.dart`

## Không thay đổi

- Không thay đổi schema SQLite/Supabase.
- Không thay đổi quota, membership, referral, payment hoặc Admin permissions.
- Không thêm dữ liệu giả vào production.
- Không kích hoạt dark theme toàn cục khi các view cũ chưa hoàn thành kiểm chứng tương phản.

## Tiêu chí hoàn thành

- Tất cả app surface dùng `AppExperience.builder`.
- Không còn raw `Scaffold` trong page production, ngoại trừ primitive nội bộ và design-system demo.
- Auth, Dashboard, Settings, Home và trạng thái hỗ trợ sử dụng token/primitive mới.
- Có contract test bảo vệ việc wiring theme và shell.
- Không đưa khóa bí mật hoặc dữ liệu sức khỏe cá nhân vào tài liệu/test.
