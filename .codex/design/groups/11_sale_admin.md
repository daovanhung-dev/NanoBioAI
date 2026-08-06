# Sale và Admin

## Goal

Giảm cường độ motion cho workspace, giữ mật độ thông tin cao và chỉ animate thay đổi có ý nghĩa.

## Current evidence

- Files: **8**.
- Page/screen: **4**.
- Files có motion: **2**.
- Files dùng duration raw: **0**.
- Files dùng color trực tiếp: **1**.
- Files gọi haptic trực tiếp: **0**.

## Group design rules

- Motion density thấp hơn consumer app.
- Status/row mutation feedback sau backend.
- Table/filter/dialog có continuity, không ambient loop.
- Admin sound mặc định off và Nabi không ambient.

## Views

| View | Entrance | State transition | Feedback | Design intent |
| --- | --- | --- | --- | --- |
| lib/app_versions/admin/features/admin_panel/presentation/pages/admin_login_page.dart | Fade-through 4 px, mật độ thấp | Filter/tab/row/status/mutation progress | Haptic nhẹ cho selection; sound mặc định tắt; success/error sau backend | Professional auth motion, focus/submit/error; không ambient quá mạnh và sound mặc định tắt. |
| lib/app_versions/admin/features/admin_panel/presentation/pages/admin_shell_page.dart | Fade-through 4 px, mật độ thấp | Filter/tab/row/status/mutation progress | Haptic nhẹ cho selection; sound mặc định tắt; success/error sau backend | Tách file rất lớn thành shell/sections/tables/dialogs; side-nav indicator, row update highlight, motion density thấp. |
| lib/sale_referral/presentation/pages/sale_participation_page.dart | Fade-through 4 px, mật độ thấp | Filter/tab/row/status/mutation progress | Haptic nhẹ cho selection; sound mặc định tắt; success/error sau backend | Terms/status progression; pending/rejected/approved semantic motion; không celebration trước review. |
| lib/sale_referral/presentation/pages/sale_shell_page.dart | Fade-through 4 px, mật độ thấp | Filter/tab/row/status/mutation progress | Haptic nhẹ cho selection; sound mặc định tắt; success/error sau backend | Tách file lớn; KPI delta, tabs/filter, payout gate và conversion status; motion vừa phải. |

## File-by-file design

| File | Kind | Role | Current evidence | Target design | Transition contract | Wave |
| --- | --- | --- | --- | --- | --- | --- |
| lib/app_versions/admin/features/admin_panel/presentation/controllers/admin_access_controller.dart | controller | AdminAccessController | Chưa có motion/feedback đáng kể | Giữ nguyên nghiệp vụ; chuẩn hóa UI phase/state identity; loại bỏ haptic trực tiếp khỏi controller và phát feedback sau khi state thành công/thất bại được xác nhận. | Stable state/identity contract | W10 Sale/Admin |
| lib/app_versions/admin/features/admin_panel/presentation/controllers/admin_controller.dart | controller | AdminLoginFailure / AdminPanelState / AdminController | Nabi×1 | Giữ nguyên nghiệp vụ; chuẩn hóa UI phase/state identity; loại bỏ haptic trực tiếp khỏi controller và phát feedback sau khi state thành công/thất bại được xác nhận. | Stable state/identity contract | W10 Sale/Admin |
| lib/app_versions/admin/features/admin_panel/presentation/pages/admin_login_page.dart | page | AdminLoginPage / _AdminLoginPageState / _WideLoginLayout / _CompactLoginLayout | AnimatedSwitcher×2, motion token×3, Semantics×1 | Professional auth motion, focus/submit/error; không ambient quá mạnh và sound mặc định tắt. | Filter/tab/row/status/mutation progress | W10 Sale/Admin |
| lib/app_versions/admin/features/admin_panel/presentation/pages/admin_shell_page.dart | page | AdminShellPage / _AdminShellPageState / _AdminAmbientBackdrop / _AdminAmbientBackdropState | controller×2, AnimatedContainer×4, AnimatedSwitcher×2, AnimatedOpacity×1, AnimatedScale×2, Colors.*×6, motion token×9, Semantics×1, Nabi×5 | Tách file rất lớn thành shell/sections/tables/dialogs; side-nav indicator, row update highlight, motion density thấp. | Filter/tab/row/status/mutation progress | W10 Sale/Admin |
| lib/app_versions/admin/features/admin_panel/presentation/widgets/admin_access_gate.dart | widget | AdminAccessGate / _AdminAccessGateState / _AdminChecking / _AdminSupport | Chưa có motion/feedback đáng kể | Trusted session states; loading/denied/revoked transition rõ và không flash protected content. | Filter/tab/row/status/mutation progress | W10 Sale/Admin |
| lib/app_versions/admin/features/wellness_rewards/presentation/admin_wellness_rewards_panel.dart | presentation_support | AdminWellnessRewardsPanel / _AdminWellnessRewardsPanelState / _AdminRewardMetrics / _AdminOfferCard | Nabi×1 | Giữ logic thuần; bổ sung semantic presentation metadata hoặc stable identity chỉ khi cần cho transition; không chứa animation, sound hay BuildContext. | Stable state/identity contract | W10 Sale/Admin |
| lib/sale_referral/presentation/pages/sale_participation_page.dart | page | SaleParticipationPage / _SaleParticipationPageState / _BuildTermsBody / _StatusNotice | Chưa có motion/feedback đáng kể | Terms/status progression; pending/rejected/approved semantic motion; không celebration trước review. | Filter/tab/row/status/mutation progress | W10 Sale/Admin |
| lib/sale_referral/presentation/pages/sale_shell_page.dart | page | SaleShellPage / _SaleShellPageState / _SalePayoutProfileGate / _SalePayoutProfileGateState | Chưa có motion/feedback đáng kể | Tách file lớn; KPI delta, tabs/filter, payout gate và conversion status; motion vừa phải. | Filter/tab/row/status/mutation progress | W10 Sale/Admin |

## Acceptance

- Không raw sound/haptic call ngoài feedback service.
- Không motion replay khi state không đổi.
- Có reduced-motion behavior.
- Có loading/empty/error/ready hoặc lý do không áp dụng.
- Targeted widget/route/state test được bổ sung trong coding wave.
