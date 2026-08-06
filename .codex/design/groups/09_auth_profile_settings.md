# Auth, profile và settings

## Goal

Làm rõ focus/validation, auth state, profile edits và cài đặt motion/sound/haptic.

## Current evidence

- Files: **10**.
- Page/screen: **7**.
- Files có motion: **1**.
- Files dùng duration raw: **0**.
- Files dùng color trực tiếp: **2**.
- Files gọi haptic trực tiếp: **0**.

## Group design rules

- Focus/validation/submit state thống nhất.
- Auth guard không flash protected surface.
- Settings cung cấp motion/haptic/sound/Nabi options.
- Success sau commit; không lộ lỗi kỹ thuật.

## Views

| View | Entrance | State transition | Feedback | Design intent |
| --- | --- | --- | --- | --- |
| lib/app_versions/v1/features/auth/presentation/pages/v1_auth_entry_page.dart | Focus-first fade-through | Loading/empty/error/ready và action result | Press visual; selection haptic; sound chỉ cho success/error/voice/milestone semantic | Giữ vai trò route forwarder/entry; không thêm motion riêng ngoài route registry. |
| lib/app_versions/v1/features/profile/presentation/pages/profile_page.dart | Focus-first fade-through | Loading/empty/error/ready và action result | Press visual; selection haptic; sound chỉ cho success/error/voice/milestone semantic | Tách editor sheet; header parallax giới hạn, avatar edit transition, save feedback sau commit. |
| lib/app_versions/v1/features/profile/presentation/profile_screen.dart | Focus-first fade-through | Loading/empty/error/ready và action result | Press visual; selection haptic; sound chỉ cho success/error/voice/milestone semantic | Nếu chỉ là alias/forwarder, giữ không UI; deprecate hoặc document route ownership. |
| lib/app_versions/v1/features/settings/presentation/pages/dev_database_viewer_page.dart | Focus-first fade-through | Loading/empty/error/ready và action result | Press visual; selection haptic; sound chỉ cho success/error/voice/milestone semantic | Developer-only dense workspace; motion tối thiểu, row highlight và refresh status; không đưa Nabi/sound. |
| lib/app_versions/v1/features/settings/presentation/pages/settings_page.dart | Focus-first fade-through | Loading/empty/error/ready và action result | Press visual; selection haptic; sound chỉ cho success/error/voice/milestone semantic | Tách sections; thêm Motion/Haptic/Sound settings; switch feedback thống nhất và không phát sound trong Admin mặc định. |
| lib/app_versions/v2/features/auth/presentation/pages/auth_gate_page.dart | Focus-first fade-through | Loading/empty/error/ready và action result | Press visual; selection haptic; sound chỉ cho success/error/voice/milestone semantic | Auth/sync/consent state dùng AnimatedSwitcher có stable key; redirect không flash; loading không loop vô nghĩa. |
| lib/app_versions/v2/features/auth/presentation/pages/auth_pages.dart | Focus-first fade-through | Loading/empty/error/ready và action result | Press visual; selection haptic; sound chỉ cho success/error/voice/milestone semantic | Tách file lớn theo page/form; tab indicator, input validation, submit morph và recovery transitions thống nhất. |

## File-by-file design

| File | Kind | Role | Current evidence | Target design | Transition contract | Wave |
| --- | --- | --- | --- | --- | --- | --- |
| lib/app_versions/v1/features/auth/presentation/pages/v1_auth_entry_page.dart | page | V1AuthEntryPage | Nabi×2 | Giữ vai trò route forwarder/entry; không thêm motion riêng ngoài route registry. | Loading/empty/error/ready và action result | W8 Auth/Profile/Settings |
| lib/app_versions/v1/features/profile/presentation/pages/profile_page.dart | page | ProfilePage / _EditProfileSheet / _EditProfileSheetState / _ProfileField | RefreshIndicator×1, Nabi×7 | Tách editor sheet; header parallax giới hạn, avatar edit transition, save feedback sau commit. | Loading/empty/error/ready và action result | W8 Auth/Profile/Settings |
| lib/app_versions/v1/features/profile/presentation/profile_screen.dart | page | ProfileScreen | Chưa có motion/feedback đáng kể | Nếu chỉ là alias/forwarder, giữ không UI; deprecate hoặc document route ownership. | Loading/empty/error/ready và action result | W8 Auth/Profile/Settings |
| lib/app_versions/v1/features/settings/presentation/pages/dev_database_viewer_page.dart | page | DevDatabaseViewerPage / _DevDatabaseViewerPageState / _DatabaseSnapshot / _DatabaseTableSnapshot | RefreshIndicator×1 | Developer-only dense workspace; motion tối thiểu, row highlight và refresh status; không đưa Nabi/sound. | Loading/empty/error/ready và action result | W8 Auth/Profile/Settings |
| lib/app_versions/v1/features/settings/presentation/pages/settings_page.dart | page | SettingsView / _ChangePasswordSheet / _ChangePasswordSheetState / _SaleSettingsEntry | Colors.*×2, RefreshIndicator×1, Nabi×25 | Tách sections; thêm Motion/Haptic/Sound settings; switch feedback thống nhất và không phát sound trong Admin mặc định. | Loading/empty/error/ready và action result | W8 Auth/Profile/Settings |
| lib/app_versions/v1/features/settings/presentation/widgets/font_scale_selector.dart | widget | FontScaleSelector | Semantics×2, Nabi×1 | Live preview, semantic labels và reduced-motion aware thumb/label transition. | Loading/empty/error/ready và action result | W8 Auth/Profile/Settings |
| lib/app_versions/v1/features/settings/presentation/widgets/guest_account_access_card.dart | widget | GuestAccountAccessCard | Chưa có motion/feedback đáng kể | Access CTA rõ, locked/guest state semantic, không dùng premium sparkle gây hiểu sai. | Loading/empty/error/ready và action result | W8 Auth/Profile/Settings |
| lib/app_versions/v2/features/auth/presentation/controllers/auth_controller.dart | controller | AuthController | Chưa có motion/feedback đáng kể | Giữ nguyên nghiệp vụ; chuẩn hóa UI phase/state identity; loại bỏ haptic trực tiếp khỏi controller và phát feedback sau khi state thành công/thất bại được xác nhận. | Stable state/identity contract | W8 Auth/Profile/Settings |
| lib/app_versions/v2/features/auth/presentation/pages/auth_gate_page.dart | page | AuthGatePage / _AuthGatePageState / _GuestConsentState / _AuthLoading | Nabi×2 | Auth/sync/consent state dùng AnimatedSwitcher có stable key; redirect không flash; loading không loop vô nghĩa. | Loading/empty/error/ready và action result | W8 Auth/Profile/Settings |
| lib/app_versions/v2/features/auth/presentation/pages/auth_pages.dart | page | V2LoginPage / _V2LoginPageState / V2RegisterPage / _V2RegisterPageState | AnimatedSwitcher×1, Colors.*×1, motion token×1, Semantics×2, Nabi×10 | Tách file lớn theo page/form; tab indicator, input validation, submit morph và recovery transitions thống nhất. | Loading/empty/error/ready và action result | W8 Auth/Profile/Settings |

## Acceptance

- Không raw sound/haptic call ngoài feedback service.
- Không motion replay khi state không đổi.
- Có reduced-motion behavior.
- Có loading/empty/error/ready hoặc lý do không áp dụng.
- Targeted widget/route/state test được bổ sung trong coding wave.
