# V2, V3, membership và FamilyPlus

## Goal

Phân biệt locked/pending/active bằng semantic state, không dùng celebration trước xác nhận backend.

## Current evidence

- Files: **7**.
- Page/screen: **6**.
- Files có motion: **0**.
- Files dùng duration raw: **0**.
- Files dùng color trực tiếp: **0**.
- Files gọi haptic trực tiếp: **0**.

## Group design rules

- Trusted status quyết định locked/pending/active/revoked.
- Pending payment không hiển thị như unlocked.
- Family subject switch có privacy-aware transition.
- Premium sparkle giới hạn, không phủ toàn view.

## Views

| View | Entrance | State transition | Feedback | Design intent |
| --- | --- | --- | --- | --- |
| lib/app_versions/v2/features/health_modules/presentation/pages/health_module_access_page.dart | State fade-through theo trusted status | Loading/empty/error/ready và action result | Press visual; selection haptic; sound chỉ cho success/error/voice/milestone semantic | Forward/locked/support states rõ, route transition không lặp và access denial không celebration. |
| lib/app_versions/v2/features/home/presentation/pages/v2_home_page.dart | State fade-through theo trusted status | Loading/empty/error/ready và action result | Press visual; selection haptic; sound chỉ cho success/error/voice/milestone semantic | Authenticated home phải dùng cùng shell/dashboard language; không tạo visual system riêng. |
| lib/app_versions/v2/features/payments/presentation/pages/membership_payment_page.dart | State fade-through theo trusted status | Loading/empty/error/ready và action result | Press visual; selection haptic; sound chỉ cho success/error/voice/milestone semantic | Plan selector morph, QR/pending state progression; success chỉ sau trusted approval, không sau submit request. |
| lib/app_versions/v2/features/wellness_rewards/presentation/pages/wellness_rewards_page.dart | State fade-through theo trusted status | Loading/empty/error/ready và action result | Press visual; selection haptic; sound chỉ cho success/error/voice/milestone semantic | Point delta, offer tabs và redemption status; animation chỉ sau ledger/backend confirmation. |
| lib/app_versions/v3/features/familyplus/presentation/pages/familyplus_page.dart | State fade-through theo trusted status | Loading/empty/error/ready và action result | Press visual; selection haptic; sound chỉ cho success/error/voice/milestone semantic | Member card insert/remove, subject switch shared indicator; cross-subject data transition có privacy shield. |
| lib/app_versions/v3/features/home/presentation/pages/v3_home_page.dart | State fade-through theo trusted status | Loading/empty/error/ready và action result | Press visual; selection haptic; sound chỉ cho success/error/voice/milestone semantic | Planned feature cards có subdued motion và trạng thái sắp có minh bạch. |

## File-by-file design

| File | Kind | Role | Current evidence | Target design | Transition contract | Wave |
| --- | --- | --- | --- | --- | --- | --- |
| lib/app_versions/v2/features/cloud_sync/presentation/controllers/user_data_sync_controller.dart | controller | UserDataSyncController | Chưa có motion/feedback đáng kể | Giữ nguyên nghiệp vụ; chuẩn hóa UI phase/state identity; loại bỏ haptic trực tiếp khỏi controller và phát feedback sau khi state thành công/thất bại được xác nhận. | Stable state/identity contract | W9 V2/V3/Membership |
| lib/app_versions/v2/features/health_modules/presentation/pages/health_module_access_page.dart | page | HealthModuleAccessPage / _HealthModuleRouteForwarder / _HealthModuleRouteForwarderState / _HealthModuleSupportPage | Nabi×2 | Forward/locked/support states rõ, route transition không lặp và access denial không celebration. | Loading/empty/error/ready và action result | W9 V2/V3/Membership |
| lib/app_versions/v2/features/home/presentation/pages/v2_home_page.dart | page | V2HomePage | Nabi×1 | Authenticated home phải dùng cùng shell/dashboard language; không tạo visual system riêng. | Loading/empty/error/ready và action result | W9 V2/V3/Membership |
| lib/app_versions/v2/features/payments/presentation/pages/membership_payment_page.dart | page | MembershipPaymentPage / _MembershipPaymentPageState / _PlanSelector / _PaymentRequestPanel | Semantics×1 | Plan selector morph, QR/pending state progression; success chỉ sau trusted approval, không sau submit request. | Loading/empty/error/ready và action result | W9 V2/V3/Membership |
| lib/app_versions/v2/features/wellness_rewards/presentation/pages/wellness_rewards_page.dart | page | WellnessRewardsPage / _WellnessRewardsPageState / _RewardSummary / _OffersTab | Semantics×1, RefreshIndicator×3, Nabi×2 | Point delta, offer tabs và redemption status; animation chỉ sau ledger/backend confirmation. | Loading/empty/error/ready và action result | W9 V2/V3/Membership |
| lib/app_versions/v3/features/familyplus/presentation/pages/familyplus_page.dart | page | FamilyPlusPage / _FamilyPlusBody / _EmptyFamilyState / _ReadyFamilyState | Chưa có motion/feedback đáng kể | Member card insert/remove, subject switch shared indicator; cross-subject data transition có privacy shield. | Loading/empty/error/ready và action result | W9 V2/V3/Membership |
| lib/app_versions/v3/features/home/presentation/pages/v3_home_page.dart | page | V3HomePage / _PlannedFeature | Nabi×1 | Planned feature cards có subdued motion và trạng thái sắp có minh bạch. | Loading/empty/error/ready và action result | W9 V2/V3/Membership |

## Acceptance

- Không raw sound/haptic call ngoài feedback service.
- Không motion replay khi state không đổi.
- Có reduced-motion behavior.
- Có loading/empty/error/ready hoặc lý do không áp dụng.
- Targeted widget/route/state test được bổ sung trong coding wave.
